import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';

import '../constants/constants.dart';
import '../constants/endpoints.dart';
import '../core/api_service.dart';
import '../core/auth_provider.dart';
import '../core/database.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class RankService {
  late String _currentSeason;
  late List<String> _activeTracks;
  late List<String> _rankTypes;
  bool _isInitialized = false;
  final DataBase _database = DataBase();
  final int chunkSize = 25;
  Timer _refreshTimer = Timer(Duration.zero, () {});
  Timer _refreshNameTimer = Timer(Duration.zero, () {});

  final _rankUpdateController = StreamController<void>.broadcast();

  Stream<void> get rankUpdates => _rankUpdateController.stream;

  late AuthProvider authProvider;

  RankService._();

  static final RankService _instance = RankService._();

  factory RankService() => _instance;

  String get currentSeason => _instance._currentSeason;

  List<String> get activeTracks => _instance._activeTracks;

  Future<void> init(AuthProvider authProvider) async {
    if (!_isInitialized) {
      this.authProvider = authProvider;

      _currentSeason = await _fetchCurrentSeason();
      _activeTracks = await _fetchSeasonTracks();

      _rankTypes = ['br', 'zb', 'rr'];

      await startRankBulkTrack();
      await checkDisplayNames();
      _scheduleDataFetch();

      _isInitialized = true;
    }
  }

  String getBasicAuthHeader() {
    return "Bearer ${authProvider.accessToken}";
  }

  Future<String> _fetchCurrentSeason() async {
    String response = await ApiService.getData(Endpoints.battlePassData, "");
    String slug = jsonDecode(response)["slug"];
    RegExp regExp = RegExp(r"(\D)(\d)");

    String replacedSlug = slug.replaceAllMapped(regExp, (Match match) {
      return "${match.group(1)}_${match.group(2)}";
    });
    return replacedSlug.replaceAll("-", "_");
  }

  Future<List<String>> _fetchSeasonTracks() async {
    List<String> tracks = ["", "", ""];

    String url = ApiService.interpolate(
        Endpoints.activeTracks, ["${DateTime.now().toIso8601String()}Z"]);

    String result = await ApiService.getData(url, getBasicAuthHeader());

    dynamic jsonObject = jsonDecode(result);

    Map<String, int> rankingTypeToIndex = {
      "ranked-br": 0,
      "ranked-zb": 1,
      "delmar-competitive": 2
    };

    for (var data in jsonObject) {
      int? index = rankingTypeToIndex[data["rankingType"]];
      if (index != null) {
        tracks[index] = data["trackguid"];
      }
    }

    return tracks;
  }

  int remapKey(String key) {
    return key == "ranked-br"
        ? 0
        : key == "ranked-zb"
            ? 1
            : 2;
  }

  Future<Database> connectToDB(String accountId) async {
    var databaseFactory = databaseFactoryFfi;
    Directory documentsDirectory = await getApplicationSupportDirectory();
    String path = join(documentsDirectory.path, "databases", "$accountId.db");
    return databaseFactory.openDatabase(path);
  }

  Future<void> createNewSeasonTable(String rankingType, Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${_currentSeason}_$rankingType (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        datetime TEXT,
        rank TEXT,
        progress INTEGER,
        daily_match_id INTEGER,
        total_progress INTEGER
      )
    ''');
  }

  Map<String, dynamic>? formatData(
      Map<String, dynamic> data, String rankingType) {
    double progress = data["promotionProgress"];
    String rank = Constants.ranks[data["currentDivision"]];
    int? ranking = data["currentPlayerRanking"];
    String update = data["lastUpdated"];
    if (update == "1970-01-01T00:00:00Z") {
      return null;
    }
    return {
      'progress': (progress / 0.01).round(),
      'rank': rank,
      'ranking': ranking,
      'update': update,
      'rankingType': rankingType
    };
  }

  Future<void> insertFirstData(Database db, Map<String, dynamic> data) async {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    await db.insert('${_currentSeason}_${data['rankingType']}', {
      'id': 0,
      'datetime': formattedDate,
      'rank': data['rank'],
      'progress': data['progress'],
      'daily_match_id': 0,
      'total_progress': data['totalProgress']
    });
  }

  Future<void> checkForNewGame(Database db, Map<String, dynamic> data) async {
    var progress = data['progress'];
    String rank = data['rank'];
    int? ranking = data['ranking'];
    String update = data['update'];
    String rankingType = data['rankingType'];

    if (ranking != null) {
      progress = ranking;
    }
    int totalProgress = progress + (Constants.ranks.indexOf(rank) * 100);

    List<Map<String, dynamic>> overallCountResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${_currentSeason}_${rankingType}');
    int overallCount = overallCountResult.first['count'];

    if (overallCount == 0) {
      await insertFirstData(db, {
        'rankingType': rankingType,
        'rank': rank,
        'progress': progress,
        'totalProgress': totalProgress
      });
      return;
    }

    List<Map<String, dynamic>> dailyMatchIdResult = await db.rawQuery(
        '''SELECT MAX(daily_match_id) as max_id FROM ${_currentSeason}_${rankingType}
        WHERE strftime('%Y-%m-%d', datetime) = DATE('now', 'localtime')''');
    int? dailyMatchId = dailyMatchIdResult.first['max_id'];

    bool check = await checkForDoubleData(db, update, rankingType);
    if (check) return;

    dailyMatchId = (dailyMatchId ?? 0) + 1;

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    await db.insert('${_currentSeason}_${rankingType}', {
      'datetime': formattedDate,
      'rank': rank,
      'progress': progress,
      'daily_match_id': dailyMatchId,
      'total_progress': totalProgress
    });
  }

  Future<bool> checkForDoubleData(
      Database db, String update, String rankingType) async {
    List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT datetime FROM ${_currentSeason}_${rankingType} ORDER BY id DESC LIMIT 1');

    if (result.isEmpty) {
      return false;
    }

    DateTime databaseDatetime =
        DateTime.parse(result.first['datetime'] as String);
    DateTime apiDatetime = DateTime.parse(update);

    return databaseDatetime.isAfter(apiDatetime) ||
        databaseDatetime.isAtSameMomentAs(apiDatetime);
  }

  Future<List> getRankedDataByAccountId(
      String accountId, String rankType) async {
    Database db = await connectToDB(accountId);
    List<Map<String, dynamic>> result = [];
    try {
      result = await db.rawQuery(
          'SELECT daily_match_id, datetime, rank, progress, total_progress FROM ${_currentSeason}_$rankType ORDER BY id DESC LIMIT 2');
    } catch (error) {
      print("Error occured: $error");
    }
    return result;
  }

  Future<List> getRankedDataBySeason(
      String accountId, String seasonName) async {
    Database db = await connectToDB(accountId);
    List<Map<String, dynamic>> result = [];
    try {
      result = await db.rawQuery('SELECT * FROM $seasonName');
    } catch (error) {
      print("Error occured: $error");
    }
    return result;
  }

  Future<void> checkDisplayNames() async {
    for (int i = 0; i < 3; i++) {
      for (final oldData in await _database.getAccountDataByType(
          i, "accountId, displayName", true)) {
        Map<String, String> newData =
            await _fetchByAccountId(oldData["accountId"]);
        if (oldData["displayName"] != newData["displayName"]) {
          _database.updatePlayerName(
              i, newData["accountId"]!, newData["displayName"]!);
        }
      }
    }
  }

  Future<void> startRankBulkTrack() async {
    List<String> tracks = _activeTracks;
    for (int i = 0; i < 3; i++) {
      List<Map<String, dynamic>> accountData =
          await _database.getAccountDataByType(i, "accountId", true);
      List<String> ids =
          accountData.map((item) => item['accountId'] as String).toList();

      List<List<String>> chunks = [];
      for (int x = 0; x < ids.length; x += chunkSize) {
        chunks.add(ids.sublist(
            x, x + chunkSize > ids.length ? ids.length : x + chunkSize));
      }

      for (List<String> chunk in chunks) {
        Map<String, dynamic> accountIds = {'accountIds': chunk};
        String bulkProgressUrl =
            ApiService.interpolate(Endpoints.bulkProgress, [tracks[i]]);
        try {
          String result = await ApiService.postData(bulkProgressUrl,
              jsonEncode(accountIds), getBasicAuthHeader(), Constants.dataJson);
          storeRankData(jsonDecode(result));
        } catch (e) {
          print('Failed to post data: $e');
        }
      }
    }
    _rankUpdateController.add(null);
  }

  void refreshMainPage() {
    _rankUpdateController.add(null);
  }

  Future<List<dynamic>> getSingleProgress(String accountId) async {
    List<String> pathParams = [
      accountId,
      "${DateTime.now().toIso8601String()}Z"
    ];
    String url = ApiService.interpolate(Endpoints.singleProgress, pathParams);

    String result = await ApiService.getData(url, getBasicAuthHeader());

    return jsonDecode(result);
  }

  Future<void> storeRankData(List<dynamic> data) async {
    for (var dat in data) {
      int rankingType = remapKey(dat["rankingType"]);
      Database db = await connectToDB(dat["accountId"]);
      await createNewSeasonTable(_rankTypes[rankingType], db);

      var formattedData = formatData(dat, _rankTypes[rankingType]);
      if (formattedData != null) {
        await checkForNewGame(db, formattedData);
      }
    }
  }

  Future<List<Map<String, String>>> search(String query) async {
    if (query.isEmpty || (query.length > 16 && query.length != 32)) {
      return [];
    }

    if (query.length == 32) {
      return [await _fetchByAccountId(query)];
    }

    final epicResults = await _fetchResultsByPlatform("epic", query);
    final psnResults = await _fetchResultsByPlatform("psn", query);
    final xboxResults = await _fetchResultsByPlatform("xbl", query);

    final allResults = [...epicResults, ...psnResults, ...xboxResults];

    if (allResults.isEmpty) {
      final result = await _fetchDisplayName(query);
      return result;
    }

    final uniqueResults = <String, Map<String, String>>{};

    for (var result in allResults) {
      final accountId = result['accountId']!;
      if (!uniqueResults.containsKey(accountId)) {
        uniqueResults[accountId] = result;
      }
    }

    return uniqueResults.values.toList();
  }

  Future<List<Map<String, String>>> _fetchResultsByPlatform(
      String platform, String query) async {
    final pathParams = [authProvider.accountId, platform, query];
    final url = ApiService.interpolate(Endpoints.userSearch, pathParams);
    final response = await ApiService.getData(url, getBasicAuthHeader());
    if (!response.contains("StatusCode:")) {
      final List<dynamic> jsonObject = jsonDecode(response);

      return jsonObject.map((item) {
        final match = item['matches'][0];
        return {
          'accountId': item["accountId"] as String,
          'platform': match["platform"] as String,
          'displayName': match["value"] as String,
        };
      }).toList();
    }
    return [];
  }

  Future<Map<String, String>> _fetchByAccountId(String accountId) async {
    final url = ApiService.interpolate(Endpoints.userByAccId, [accountId]);
    final response = await ApiService.getData(url, getBasicAuthHeader());
    Map<String, dynamic> jsonObj = jsonDecode(response)[0];
    if (jsonObj.containsKey("displayName")) {
      return {
        'accountId': jsonObj["id"] as String,
        'platform': "epic",
        'displayName': jsonObj["displayName"] as String
      };
    } else {
      if (jsonObj["externalAuths"].containsKey("psn")) {
        return {
          'accountId': jsonObj["id"] as String,
          'platform': "psn",
          'displayName':
              jsonObj["externalAuths"]["psn"]["externalDisplayName"] as String
        };
      } else if (jsonObj["externalAuths"].containsKey("xbl")) {
        return {
          'accountId': jsonObj["id"] as String,
          'platform': "xbl",
          'displayName':
              jsonObj["externalAuths"]["xbl"]["externalDisplayName"] as String
        };
      }
    }
    return {};
  }

  Future<Map<String, String>> _fetchDisplayNameByPlatform(
      String displayName, String platform) async {
    String url;
    if (platform != "epic") {
      final pathParams = [platform, displayName];
      url = ApiService.interpolate(Endpoints.userByNameExt, pathParams);
    } else {
      final pathParams = [displayName];
      url = ApiService.interpolate(Endpoints.userByName, pathParams);
    }
    final response = await ApiService.getData(url, getBasicAuthHeader());

    if (!response.contains("StatusCode:") && response != "[]") {
      final dynamic jsonObject = jsonDecode(response);
      if (platform == "epic") {
        return {
          "accountId": jsonObject["id"] as String,
          "displayName": jsonObject["displayName"] as String,
          "platform": platform
        };
      } else {
        String displayName;
        if (jsonObject[0].containsKey("displayName")) {
          displayName = jsonObject[0]["displayName"];
        } else {
          displayName =
              jsonObject[0]["externalAuths"][platform]["externalDisplayName"];
        }
        return {
          "accountId": jsonObject[0]["id"] as String,
          "displayName": displayName,
          "platform": platform
        };
      }
    } else {
      return {};
    }
  }

  Future<List<Map<String, String>>> _fetchDisplayName(
      String displayName) async {
    Map<String, String> epic =
        await _fetchDisplayNameByPlatform(displayName, "epic");
    Map<String, String> psn =
        await _fetchDisplayNameByPlatform(displayName, "psn");
    Map<String, String> xbl =
        await _fetchDisplayNameByPlatform(displayName, "xbl");

    if (psn.isNotEmpty &&
        epic.isNotEmpty &&
        psn["accountId"] == epic["accountId"]) {
      psn = {};
    }
    if (xbl.isNotEmpty) {
      if (psn.isNotEmpty && xbl["accountId"] == psn["accountId"]) {
        xbl = {};
      }
      if (epic.isNotEmpty && xbl["accountId"] == epic["accountId"]) {
        xbl = {};
      }
    }

    return [epic, psn, xbl].where((map) => map.isNotEmpty).toList();
  }

  void _scheduleDataFetch() {
    _refreshTimer.cancel();
    _refreshNameTimer.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      startRankBulkTrack();
    });
    _refreshNameTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      checkDisplayNames();
    });
  }

  void dispose() {
    _rankUpdateController.close();
  }
}
