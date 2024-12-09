import 'dart:async';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fortnite_ranked_tracker/core/avatar_manager.dart';

import '../constants/constants.dart';
import '../constants/endpoints.dart';
import '../core/api_service.dart';
import 'talker_service.dart';

class RankService {
  final _rankUpdateController = StreamController<List?>.broadcast();

  Stream<List?> get rankUpdates => _rankUpdateController.stream;

  RankService._();

  static final RankService _instance = RankService._();

  factory RankService() => _instance;

  Future<String> getBasicAuthHeader() async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);
      return "bearer $token";
    } catch (e) {
      talker.error('Failed to get FirebaseAuth Token');
      return "";
    }
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

  Future<List<Map<String, dynamic>>> getDashboardData() async {
    List result = await ApiService()
        .getData(Endpoints.dashboardData, await getBasicAuthHeader());
    return result.cast<Map<String, dynamic>>();
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

    final avatarManager = AvatarManager();

    for (var element in resultCasted) {
      if (!element.containsKey("accountAvatar")) {
        element["accountAvatar"] =
            avatarManager.getAvatar(element["accountId"]);
      }
    }

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
    _rankUpdateController.sink.add(data);
  }

  Future<List<Map<String, dynamic>>> fetchEvents() async {
    final List tournaments =
        await ApiService().getData(Endpoints.eventInfo, "");

    return tournaments.cast();
  }

  Future<List<Map<String, dynamic>>> getEventLeaderboard(
      String eventId, String windowId) async {
    try {
      final List<int> leaderboardResponse = await ApiService().getData(
          Endpoints.eventLeaderboard, "",
          queryParams: {"eventId": eventId, "windowId": windowId},
          responseType: ResponseType.bytes);

      final List<int> decodedData =
          BZip2Decoder().decodeBytes(leaderboardResponse);

      final String decodedString = utf8.decode(decodedData);
      final List<dynamic> jsonResponse = json.decode(decodedString);

      return jsonResponse
          .map<Map<String, dynamic>>((item) => item as Map<String, dynamic>)
          .toList();
    } catch (e) {
      talker.error('Error while getting event leaderboard: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getLeadeboardEntryInfo(
      int rank, String eventId, String windowId) async {
    final Map<String, dynamic> response = await ApiService().getData(
        Endpoints.eventEntryInfo, "", queryParams: {
      "rank": rank.toString(),
      "eventId": eventId,
      "windowId": windowId
    });

    return response;
  }
}
