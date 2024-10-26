import 'dart:async';
import 'dart:convert';
import 'package:fetch_client/fetch_client.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'package:http/http.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../constants/constants.dart';
import '../constants/endpoints.dart';
import '../core/api_service.dart';

class RankService {
  // late String _currentSeason;
  // late List<String> _activeTracks;
  // late List<String> _rankTypes;
  bool _isInitialized = false;
  // final DataBase _database = DataBase();
  final int chunkSize = 25;
  // Timer _refreshTimer = Timer(Duration.zero, () {});
  // Timer _refreshNameTimer = Timer(Duration.zero, () {});
  // String accountAvatar = "";
  // String accountDisplayName = "";
  // bool lastServerStatus = true;

  final _rankUpdateController = StreamController<List?>.broadcast();

  Stream<List?> get rankUpdates => _rankUpdateController.stream;

  late Talker talker;

  RankService._();

  static final RankService _instance = RankService._();

  factory RankService() => _instance;

  Future<void> init(Talker talker) async {
    if (!_isInitialized) {
      this.talker = talker;

      _isInitialized = true;
    }
  }

  Future<String> getBasicAuthHeader() async {
    return "bearer ${await FirebaseAuth.instance.currentUser?.getIdToken(true)}";
  }

  Future<void> afterRegister(UserCredential userCredential) async {
    await ApiService().postData(
        Endpoints.afterRegister,
        jsonEncode(
            {"idToken": "${await userCredential.user!.getIdToken(true)}"}),
        await getBasicAuthHeader(),
        Constants.dataJson);
  }

  Future<List<Map<String, dynamic>>> searchByQuery(String query,
      {bool onlyAccountId = false, bool returnAll = false}) async {
    List result = await ApiService().getData(
        Endpoints.searchByQuery, await getBasicAuthHeader(),
        queryParams: {
          "query": query,
          "onlyAccountId": onlyAccountId.toString(),
          "returnAll": returnAll.toString()
        });
    return result.cast<Map<String, dynamic>>();
  }

  Future<List> getSingleProgress(String accountId) async {
    List result = await ApiService().getData(
        Endpoints.singleProgress, await getBasicAuthHeader(),
        queryParams: {"accountId": accountId});

    return result;
  }

  Future<List> getPlayerTracking(String accountId) async {
    List result = await ApiService().getData(
        Endpoints.playerTracking, await getBasicAuthHeader(),
        queryParams: {"accountId": accountId});

    return result.cast();
  }

  Future<void> setPlayerTracking(
      String rankingType, bool value, String accountId) async {
    await ApiService().postData(
        Endpoints.playerTracking,
        jsonEncode({"rankingType": rankingType, "value": value}),
        await getBasicAuthHeader(),
        Constants.dataJson,
        queryParams: {"accountId": accountId});
  }

  Future<bool> getPlayerExisting(String accountId) async {
    Map<String, dynamic> result = await ApiService().getData(
        Endpoints.playerExisting, await getBasicAuthHeader(),
        queryParams: {"accountId": accountId});

    return result["userExists"];
  }

  Future<String?> getPlayerNickName(String accountId) async {
    dynamic result = await ApiService().getData(
        Endpoints.nickName, await getBasicAuthHeader(),
        queryParams: {"accountId": accountId});

    return result.isEmpty ? null : result;
  }

  Future<void> setPlayerNickName(String accountId, String nickName) async {
    await ApiService().postData(
        Endpoints.nickName,
        jsonEncode({"nickName": nickName}),
        await getBasicAuthHeader(),
        Constants.dataJson,
        queryParams: {"accountId": accountId});
  }

  Stream<List<Map<String, dynamic>>> subscribeToDB() async* {
    final controller = StreamController<List<Map<String, dynamic>>>();

    List<Map<String, dynamic>> currentData = [];

    if (kIsWeb) {
      final client = FetchClient(mode: RequestMode.cors);
      final url = Uri.parse(Endpoints.subscribe);
      final headers = {"Authorization": await getBasicAuthHeader()};
      StreamedResponse response =
          await client.send(Request('GET', url)..headers.addAll(headers));

      if (response.statusCode == 200) {
        response.stream.listen(
          (onData) {
            final textData = utf8.decode(onData);

            if (textData.contains("data:")) {
              final dataIndex = textData.indexOf("data: ") + "data: ".length;
              final payload = textData.substring(dataIndex).trim();

              try {
                final jsonData = jsonDecode(payload);
                final jsonData2 = jsonDecode(jsonData) as List;
                currentData = jsonData2.cast<Map<String, dynamic>>();
                controller.add(List.from(currentData));
              } catch (e) {
                talker.error("Failed to decode JSON: $e");
              }
            }
          },
          onError: (error) {
            talker.error("Stream error: $error");
          },
          onDone: () {
            client.close();
          },
        );
      }
    } else {
      SSEClient.subscribeToSSE(
        method: SSERequestType.GET,
        url: Endpoints.subscribe,
        header: {"Authorization": await getBasicAuthHeader()},
      ).listen((event) {
        String eventData = event.data!.trim();
        if (eventData != "undefined") {
          eventData = eventData.substring(1, eventData.length - 1);
          eventData = eventData.replaceAll(r'\"', '"');

          final List decodedData = jsonDecode(eventData);

          currentData = decodedData.cast<Map<String, dynamic>>();

          controller.add(List.from(currentData));
        }
      });
    }

    yield* controller.stream;

    await controller.close();
  }

  Future<List<Map<String, dynamic>>> getAccountsWithSeasons(
      {limit = 1, detailed = false}) async {
    List result = await ApiService().getData(
        Endpoints.accounts, await getBasicAuthHeader(), queryParams: {
      "limit": limit.toString(),
      "detailed": detailed.toString()
    });

    List<Map<String, dynamic>> resultCasted =
        result.cast<Map<String, dynamic>>();

    resultCasted.sort(
        (a, b) => (a['displayName'] as String).compareTo(b['displayName']));

    return resultCasted;
  }

  Future<List<Map<String, dynamic>>> getTrackedSeasons(String accountId,
      {int limit = 1}) async {
    List result = await ApiService().getData(
        Endpoints.trackedSeasons, await getBasicAuthHeader(),
        queryParams: {"accountId": accountId, "limit": limit.toString()});

    List<Map<String, dynamic>> resultCasted =
        result.cast<Map<String, dynamic>>();

    return resultCasted;
  }

  Future<Map<String, dynamic>> getSeasonBySeasonId(
      String accountId, String seasonId,
      {String sortBy = "id", bool isAscending = false}) async {
    Map result = await ApiService()
        .getData(Endpoints.getSeason, await getBasicAuthHeader(), queryParams: {
      "accountId": accountId,
      "seasonId": seasonId,
      "sortBy": sortBy,
      "isAscending": isAscending.toString()
    });

    return result.cast();
  }

  Future<void> updateDataEdited(
    List<Map<String, dynamic>> data,
  ) async {
    await ApiService().postData(Endpoints.updatePlayer, {"data": data},
        await getBasicAuthHeader(), Constants.dataJson);
  }

  void emitDataRefresh({List? data}) {
    _rankUpdateController.add(data);
  }
}



//   String getBasicAuthHeader() {
//     return "";
//   }

//   Stream<String> getAccountAvatar() async* {
//     yield accountAvatar;
//     while (true) {
//       // accountAvatar = (await getAccountAvatarById(
//       //     authProvider.accountId))[authProvider.accountId]!;
//       yield accountAvatar;

//       await Future.delayed(const Duration(seconds: 10));
//     }
//   }

//   Stream<bool> getServerStatusStream() async* {
//     yield lastServerStatus;
//     while (true) {
//       Map<String, dynamic> response = await ApiService()
//           .getData(Endpoints.serverStatus, getBasicAuthHeader());
//       bool status = response["status"] == "UP" ? true : false;
//       lastServerStatus = status;
//       yield status;

//       await Future.delayed(const Duration(seconds: 10));
//     }
//   }

//   Future<Map<String, String>> getAccountAvatarById(
//       String accountIdString) async {
//     Map<String, String> accountAvatarMap = {};
//     List<String> accountIds = accountIdString.split(",");

//     List response = await ApiService().getData(
//         Endpoints.accountAvatar, getBasicAuthHeader(),
//         queryParams: {"accountIds": accountIdString});

//     for (Map accountAvatar in response) {
//       List<String> avatarId = (accountAvatar["avatarId"] as String).split(":");
//       if (avatarId.isEmpty) {
//         continue;
//       }
//       accountAvatarMap[accountAvatar["accountId"]] = ApiService()
//           .addPathParams(Endpoints.skinIcon, {"skinId": avatarId[1]});
//     }
//     for (String accountId in accountIds) {
//       if (!accountAvatarMap.containsKey(accountId)) {
//         accountAvatarMap[accountId] = ApiService().addPathParams(
//             Endpoints.skinIcon, {"skinId": Constants.defaultSkinId});
//       }
//     }
//     return accountAvatarMap;
//   }

//   Future<String> getDisplayName() async {
//     if (accountDisplayName.isEmpty) {
//       // Map response = (await fetchByAccountId(authProvider.accountId)).first;
//       accountDisplayName = "test";
//     }
//     return accountDisplayName;
//   }

//   Future<String> _fetchCurrentSeason() async {
//     return "chapter_5_season_4";
//     //TODO The old endpoint is now deprecated and until we find a new one to get the current season the season is just hardcoded
//   }

//   Future<List<String>> _fetchSeasonTracks() async {
//     List<String> tracks = ["", "", "", "", ""];

//     dynamic jsonObject = await ApiService().getData(
//         Endpoints.activeTracks, getBasicAuthHeader(),
//         pathParams: {'activeBy': "${DateTime.now().toIso8601String()}Z"});

//     Map<String, int> rankingTypeToIndex = {
//       "ranked-br": 0,
//       "ranked-zb": 1,
//       "delmar-competitive": 2,
//       "ranked_blastberry_build": 3,
//       "ranked_blastberry_nobuild": 4
//     };

//     for (var data in jsonObject) {
//       int? index = rankingTypeToIndex[data["rankingType"]];
//       if (index != null) {
//         tracks[index] = data["trackguid"];
//       }
//     }

//     return tracks;
//   }

//   int remapKey(String key) {
//     return key == "ranked-br"
//         ? 0
//         : key == "ranked-zb"
//             ? 1
//             : key == "delmar-competitive"
//                 ? 2
//                 : key == "ranked_blastberry_build"
//                     ? 3
//                     : 4;
//   }

//   Future<Database> connectToDB(String accountId) async {
//     var databaseFactory = databaseFactoryFfi;
//     Directory documentsDirectory = await getApplicationSupportDirectory();
//     String path = join(documentsDirectory.path, "databases", "$accountId.db");
//     return databaseFactory.openDatabase(path);
//   }

//   Future<void> createNewSeasonTable(String rankingType, Database db) async {
//     await db.execute('''
//       CREATE TABLE IF NOT EXISTS ${_currentSeason}_$rankingType (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         datetime TEXT,
//         rank TEXT,
//         progress INTEGER,
//         daily_match_id INTEGER,
//         total_progress INTEGER
//       )
//     ''');
//   }

//   Map<String, dynamic>? formatData(
//       Map<String, dynamic> data, String rankingType) {
//     double progress = data["promotionProgress"];
//     String rank = Constants.ranks[data["currentDivision"]];
//     int? ranking = data["currentPlayerRanking"];
//     String update = data["lastUpdated"];
//     if (update == "1970-01-01T00:00:00Z") {
//       return null;
//     }
//     return {
//       'progress': (progress / 0.01).round(),
//       'rank': rank,
//       'ranking': ranking,
//       'update': update,
//       'rankingType': rankingType
//     };
//   }

//   Future<void> insertFirstData(Database db, Map<String, dynamic> data) async {
//     DateTime now = DateTime.now();
//     String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

//     await db.insert('${_currentSeason}_${data['rankingType']}', {
//       'id': 0,
//       'datetime': formattedDate,
//       'rank': data['rank'],
//       'progress': data['progress'],
//       'daily_match_id': 0,
//       'total_progress': data['totalProgress']
//     });
//   }

//   Future<void> checkForNewGame(Database db, Map<String, dynamic> data) async {
//     var progress = data['progress'];
//     String rank = data['rank'];
//     int? ranking = data['ranking'];
//     String update = data['update'];
//     String rankingType = data['rankingType'];

//     if (ranking != null) {
//       progress = ranking;
//     }
//     int totalProgress = progress + (Constants.ranks.indexOf(rank) * 100);

//     List<Map<String, dynamic>> overallCountResult = await db.rawQuery(
//         'SELECT COUNT(*) as count FROM ${_currentSeason}_$rankingType');
//     int overallCount = overallCountResult.first['count'];

//     if (overallCount == 0) {
//       await insertFirstData(db, {
//         'rankingType': rankingType,
//         'rank': rank,
//         'progress': progress,
//         'totalProgress': totalProgress
//       });
//       return;
//     }

//     List<Map<String, dynamic>> dailyMatchIdResult = await db.rawQuery(
//         '''SELECT MAX(daily_match_id) as max_id FROM ${_currentSeason}_$rankingType
//         WHERE strftime('%Y-%m-%d', datetime) = DATE('now', 'localtime')''');
//     int? dailyMatchId = dailyMatchIdResult.first['max_id'];

//     bool check = await checkForDoubleData(db, update, rankingType);
//     if (check) return;

//     dailyMatchId = (dailyMatchId ?? 0) + 1;

//     DateTime now = DateTime.now();
//     String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

//     await db.insert('${_currentSeason}_$rankingType', {
//       'datetime': formattedDate,
//       'rank': rank,
//       'progress': progress,
//       'daily_match_id': dailyMatchId,
//       'total_progress': totalProgress
//     });
//   }

//   Future<bool> checkForDoubleData(
//       Database db, String update, String rankingType) async {
//     List<Map<String, dynamic>> result = await db.rawQuery(
//         'SELECT datetime FROM ${_currentSeason}_$rankingType ORDER BY id DESC LIMIT 1');

//     if (result.isEmpty) {
//       return false;
//     }

//     DateTime databaseDatetime =
//         DateTime.parse(result.first['datetime'] as String);
//     DateTime apiDatetime = DateTime.parse(update);

//     apiDatetime = apiDatetime.toLocal();

//     apiDatetime = DateTime(apiDatetime.year, apiDatetime.month, apiDatetime.day,
//         apiDatetime.hour, apiDatetime.minute, apiDatetime.second);

//     return databaseDatetime.isAfter(apiDatetime) ||
//         databaseDatetime.isAtSameMomentAs(apiDatetime);
//   }

//   Future<List> getRankedDataByAccountId(
//       String accountId, String rankType) async {
//     Database db = await connectToDB(accountId);
//     List<Map<String, dynamic>> result = [];
//     try {
//       var tableExists = await db.rawQuery(
//           "SELECT name FROM sqlite_master WHERE type='table' AND name='${_currentSeason}_$rankType'");
//       if (tableExists.isEmpty) {
//         return result;
//       }
//       result = await db.rawQuery(
//           'SELECT daily_match_id, datetime, rank, progress, total_progress FROM ${_currentSeason}_$rankType ORDER BY id DESC LIMIT 2');
//     } catch (error) {
//       talker.error("Error occured: $error");
//     }
//     return result;
//   }

//   Future<List> getRankedDataBySeason(
//       String accountId, String seasonName) async {
//     Database db = await connectToDB(accountId);
//     List<Map<String, dynamic>> result = [];
//     try {
//       result = await db.rawQuery('SELECT * FROM $seasonName');
//     } catch (error) {
//       talker.error("Error occured: $error");
//     }
//     return result;
//   }

//   Future<void> checkDisplayNames() async {
//     final accountDataList = await _database.getAllAccounts();

//     final updateFutures = accountDataList.map((oldData) async {
//       final newData = (await fetchByAccountId(oldData["accountId"])).first;
//       if (oldData["displayName"] != newData["displayName"]) {
//         await _database.updatePlayerName(
//             newData["accountId"]!, newData["displayName"]!);
//       }
//     }).toList();

//     await Future.wait(updateFutures);
//   }

//   Future<void> startRankBulkTrack() async {
//     List<String> tracks = _activeTracks;
//     for (int i = 0; i < tracks.length; i++) {
//       List<Map<String, dynamic>> accountData =
//           await _database.getAccountDataByType(i, "accountId", true);
//       List<String> ids =
//           accountData.map((item) => item['accountId'] as String).toList();

//       List<List<String>> chunks = [];
//       for (int x = 0; x < ids.length; x += chunkSize) {
//         chunks.add(ids.sublist(
//             x, x + chunkSize > ids.length ? ids.length : x + chunkSize));
//       }

//       for (List<String> chunk in chunks) {
//         Map<String, dynamic> accountIds = {'accountIds': chunk};
//         try {
//           dynamic result = await ApiService().postData(Endpoints.bulkProgress,
//               jsonEncode(accountIds), getBasicAuthHeader(), Constants.dataJson,
//               pathParams: {"trackguid": tracks[i]});
//           storeRankData(result);
//         } catch (e) {
//           talker.error('Failed to post data: $e');
//         }
//       }
//     }
//     _rankUpdateController.add(null);
//   }

//   Future<List<dynamic>> getSingleProgress(String accountId) async {
//     dynamic result = await ApiService().getData(
//         Endpoints.singleProgress, getBasicAuthHeader(),
//         pathParams: {"accountId": accountId},
//         queryParams: {"endsAfter": "${DateTime.now().toIso8601String()}Z"});

//     return result;
//   }

//   Future<void> storeRankData(List<dynamic> data) async {
//     for (var dat in data) {
//       int rankingType = remapKey(dat["rankingType"]);
//       Database db = await connectToDB(dat["accountId"]);
//       await createNewSeasonTable(_rankTypes[rankingType], db);

//       var formattedData = formatData(dat, _rankTypes[rankingType]);
//       if (formattedData != null) {
//         await checkForNewGame(db, formattedData);
//       }
//     }
//   }

//   Future<List<Map<String, dynamic>>> search(String query) async {
//     if (query.isEmpty || (query.length > 16 && query.length != 32)) {
//       return [];
//     }

//     if (query.length == 32) {
//       var result = await fetchByAccountId(query);
//       if (result.isNotEmpty) {
//         return [(await fetchByAccountId(query)).first];
//       }
//       return [];
//     }

//     final epicResults = await _fetchResultsByPlatform("epic", query);
//     final psnResults = await _fetchResultsByPlatform("psn", query);
//     final xboxResults = await _fetchResultsByPlatform("xbl", query);

//     final allResults = [...epicResults, ...psnResults, ...xboxResults];

//     if (allResults.isEmpty) {
//       final result = await _fetchDisplayName(query);
//       return result;
//     }

//     final uniqueResults = <String, Map<String, String>>{};

//     for (var result in allResults) {
//       final accountId = result['accountId']!;
//       if (!uniqueResults.containsKey(accountId)) {
//         uniqueResults[accountId] = result;
//       }
//     }

//     return uniqueResults.values.toList();
//   }

//   Future<List<Map<String, String>>> _fetchResultsByPlatform(
//       String platform, String query) async {
//     return [];
//     // List jsonObject = await ApiService().getData(
//     //     Endpoints.userSearch, getBasicAuthHeader(),
//     //     pathParams: {"accountId": authProvider.accountId},
//     //     queryParams: {"platform": platform, "prefix": query});

//     // if (!jsonObject.contains("StatusCode:")) {
//     //   return jsonObject.map((item) {
//     //     final match = item['matches'][0];
//     //     return {
//     //       'accountId': item["accountId"] as String,
//     //       'platform': match["platform"] as String,
//     //       'displayName': match["value"] as String,
//     //     };
//     //   }).toList();
//     // }
//     // return [];
//   }

//   Future<List<Map<String, dynamic>>> fetchByAccountId(String accountId,
//       {List<String>? accountIds, bool returnAll = false}) async {
//     List<Map<String, dynamic>> results = [];

//     if (accountIds != null) {
//       int chunkSize = 100;
//       for (int i = 0; i < accountIds.length; i += chunkSize) {
//         List<String> chunk = accountIds.sublist(
//             i,
//             i + chunkSize > accountIds.length
//                 ? accountIds.length
//                 : i + chunkSize);

//         List<Map<String, dynamic>> chunkResults =
//             await _fetchChunkByAccountId(chunk, returnAll: returnAll);
//         results.addAll(chunkResults);
//       }
//     } else {
//       List<Map<String, dynamic>> singleResult =
//           await _fetchChunkByAccountId([accountId], returnAll: returnAll);
//       results.addAll(singleResult);
//     }

//     return results;
//   }

//   Future<List<Map<String, dynamic>>> _fetchChunkByAccountId(
//       List<String> accountIdChunk,
//       {bool returnAll = false}) async {
//     List<Map<String, dynamic>> results = [];

//     Map<String, dynamic> queryParams = {"accountId": accountIdChunk};

//     List<dynamic> response = await ApiService().getData(
//         Endpoints.userByAccId, getBasicAuthHeader(),
//         queryParams: queryParams) as List<dynamic>;

//     for (Map<String, dynamic> jsonObj in response) {
//       Map<String, dynamic> result = {};
//       Map<String, dynamic> allResults = {};

//       if (jsonObj.containsKey("displayName")) {
//         result = {
//           'accountId': jsonObj["id"] as String,
//           'platform': "epic",
//           'displayName': jsonObj["displayName"] as String
//         };
//         allResults.addAll({"epic": result});
//       }
//       if (jsonObj["externalAuths"].containsKey("psn") &&
//           (result.isEmpty || returnAll)) {
//         result = {
//           'accountId': jsonObj["id"] as String,
//           'platform': "psn",
//           'displayName':
//               jsonObj["externalAuths"]["psn"]["externalDisplayName"] as String
//         };
//         allResults.addAll({"psn": result});
//       }
//       if (jsonObj["externalAuths"].containsKey("xbl") &&
//           (result.isEmpty || returnAll)) {
//         result = {
//           'accountId': jsonObj["id"] as String,
//           'platform': "xbl",
//           'displayName':
//               jsonObj["externalAuths"]["xbl"]["externalDisplayName"] as String
//         };
//         allResults.addAll({"xbl": result});
//       }

//       if (returnAll) {
//         results.add(allResults);
//         continue;
//       }

//       if (result.isNotEmpty) {
//         results.add(result);
//       }
//     }

//     return results;
//   }

//   Future<Map<String, String>> _fetchDisplayNameByPlatform(
//       String displayName, String platform) async {
//     String url;
//     Map<String, String> pathParams;
//     if (platform != "epic") {
//       url = Endpoints.userByNameExt;
//       pathParams = {"authType": platform, "displayName": displayName};
//     } else {
//       url = Endpoints.userByName;
//       pathParams = {"displayName": displayName};
//     }
//     dynamic jsonObject = await ApiService()
//         .getData(url, getBasicAuthHeader(), pathParams: pathParams);

//     if (jsonObject.isNotEmpty) {
//       if (platform == "epic") {
//         return {
//           "accountId": jsonObject["id"] as String,
//           "displayName": jsonObject["displayName"] as String,
//           "platform": platform
//         };
//       } else {
//         String displayName;
//         if (jsonObject[0].containsKey("displayName")) {
//           displayName = jsonObject[0]["displayName"];
//         } else {
//           displayName =
//               jsonObject[0]["externalAuths"][platform]["externalDisplayName"];
//         }
//         return {
//           "accountId": jsonObject[0]["id"] as String,
//           "displayName": displayName,
//           "platform": platform
//         };
//       }
//     } else {
//       return {};
//     }
//   }

//   Future<List<Map<String, String>>> _fetchDisplayName(
//       String displayName) async {
//     Map<String, String> epic =
//         await _fetchDisplayNameByPlatform(displayName, "epic");
//     Map<String, String> psn =
//         await _fetchDisplayNameByPlatform(displayName, "psn");
//     Map<String, String> xbl =
//         await _fetchDisplayNameByPlatform(displayName, "xbl");

//     if (psn.isNotEmpty &&
//         epic.isNotEmpty &&
//         psn["accountId"] == epic["accountId"]) {
//       psn = {};
//     }
//     if (xbl.isNotEmpty) {
//       if (psn.isNotEmpty && xbl["accountId"] == psn["accountId"]) {
//         xbl = {};
//       }
//       if (epic.isNotEmpty && xbl["accountId"] == epic["accountId"]) {
//         xbl = {};
//       }
//     }

//     return [epic, psn, xbl].where((map) => map.isNotEmpty).toList();
//   }

//   void _scheduleDataFetch() {
//     _refreshTimer.cancel();
//     _refreshNameTimer.cancel();
//     _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
//       startRankBulkTrack();
//     });
//     _refreshNameTimer = Timer.periodic(const Duration(hours: 1), (timer) {
//       checkDisplayNames();
//     });
//   }

//   void dispose() {
//     _rankUpdateController.close();
//   }
// }
