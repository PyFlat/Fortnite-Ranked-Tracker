import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auth_flow_example/constants/constants.dart';
import 'package:auth_flow_example/constants/endpoints.dart';
import 'package:auth_flow_example/core/api_service.dart';
import 'package:auth_flow_example/core/auth_provider.dart';
import 'package:auth_flow_example/core/database.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class RankService {
  late String _currentSeason;
  late List<String> _rankTypes;
  bool _isInitialized = false;
  final DataBase _database = DataBase();
  final int chunkSize = 25;
  Timer _refreshTimer = Timer(Duration.zero, () {});

  late BuildContext _buildContext;

  RankService._();

  static final RankService _instance = RankService._();

  factory RankService() => _instance;

  String get currentSeason => _instance._currentSeason;

  Future<void> init(BuildContext context) async {
    if (!_isInitialized) {
      _currentSeason = await _fetchCurrentSeason();
      _rankTypes = ['br', 'zb', 'rr'];
      _buildContext = context;
      _scheduleDataFetch();
      _isInitialized = true;
    }
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
    await db.insert('${_currentSeason}_${data['rankingType']}', {
      'id': 0,
      'datetime': DateTime.now().toIso8601String(),
      'rank': data['rank'],
      'progress': data['progress'],
      'daily_match_id': 0,
      'total_progress': data['ranking']
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
        WHERE strftime('%Y-%m-%d', datetime) = DATE('now')''');
    int? dailyMatchId = dailyMatchIdResult.first['max_id'];

    bool check = await checkForDoubleData(db, update, rankingType);
    if (check) return;

    dailyMatchId = (dailyMatchId ?? 0) + 1;

    await db.insert('${_currentSeason}_${rankingType}', {
      'datetime': DateTime.now().toIso8601String(),
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
      //print("Error occured: $error");
    }
    return result;
  }

  Future<void> startRankBulkTrack() async {
    final authProvider =
        Provider.of<AuthProvider>(_buildContext, listen: false);
    List<String> tracks = ["N4PK1N", "L1GHT5", "rrwpwg"];
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
        String headerAuthorization = "Bearer ${authProvider.accessToken}";
        try {
          String result = await ApiService.postData(bulkProgressUrl,
              jsonEncode(accountIds), headerAuthorization, Constants.dataJson);
          print(bulkProgressUrl);
          storeRankData(jsonDecode(result));
        } catch (e) {
          print('Failed to post data: $e');
        }
      }
    }
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

  void _scheduleDataFetch() {
    _refreshTimer.cancel();
    _refreshTimer = Timer(const Duration(seconds: 2), () {
      startRankBulkTrack();
    });
  }
}
