import 'dart:async';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fortnite_ranked_tracker/core/avatar_manager.dart';
import 'package:intl/intl.dart';

import '../constants/constants.dart';
import '../constants/endpoints.dart';
import '../core/api_service.dart';
import 'talker_service.dart';

class RankService {
  final _rankUpdateController = StreamController<List?>.broadcast();

  Stream<List?> get rankUpdates => _rankUpdateController.stream;

  final _rankCardIndexController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get rankCardIndexUpdates =>
      _rankCardIndexController.stream;

  RankService._();

  static final RankService _instance = RankService._();

  factory RankService() => _instance;

  List<Map<String, String>> modes = [];

  Future<void> init() async {
    modes = await getRankedModes();
    Timer.periodic(Duration(hours: 1), (timer) async {
      modes = await getRankedModes();
    });
  }

  Future<String> getBasicAuthHeader() async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);
      return "bearer $token";
    } catch (e) {
      talker.error('Failed to get FirebaseAuth Token');
      return "";
    }
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

  Future<void> setPlayerIndex(String accountId, int index) async {
    await ApiService().postData(Endpoints.index, jsonEncode({"index": index}),
        await getBasicAuthHeader(), Constants.dataJson,
        queryParams: {"accountId": accountId});
  }

  Future<void> setAccountAvatar(String accountId, String avatar) async {
    await ApiService().postData(
        Endpoints.accountAvatar,
        jsonEncode({"avatar": avatar}),
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
      if (!element.containsKey("accountAvatar") ||
          element["accountAvatar"] == "random") {
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
      {String sortBy = "datetime", bool isAscending = false}) async {
    Map result = await ApiService()
        .getData(Endpoints.getSeason, await getBasicAuthHeader(), queryParams: {
      "accountId": accountId,
      "seasonId": seasonId,
      "sortBy": sortBy,
      "isAscending": isAscending.toString()
    });

    for (var row in result["data"]) {
      row["rank"] = row["totalProgress"] > 1700
          ? "Unreal"
          : Constants.ranks[row["totalProgress"] ~/ 100];

      row["progress"] = row["totalProgress"] > 1700
          ? "#${row["totalProgress"] - 1700}"
          : "${row["totalProgress"] % 100}%";

      row["datetime"] = DateFormat("dd.MM.yyyy HH:mm")
          .format(DateTime.parse(row["datetime"]).toLocal());
    }

    return result.cast();
  }

  Future<void> updateDataEdited(
    List<Map<String, dynamic>> data,
  ) async {
    await ApiService().postData(
        Endpoints.updatePlayer,
        jsonEncode({"data": data}),
        await getBasicAuthHeader(),
        Constants.dataJson);
  }

  void emitDataRefresh({List? data}) {
    _rankUpdateController.sink.add(data);
  }

  void cardIndexUpdated(Map<String, dynamic> data) {
    _rankCardIndexController.sink.add(data);
  }

  Future<List<Map<String, dynamic>>> fetchEvents() async {
    final List tournaments = await ApiService()
        .getData(Endpoints.eventInfo, await getBasicAuthHeader());

    return tournaments.cast();
  }

  Future<List<Map<String, dynamic>>> fetchEventsHistory({int? days}) async {
    final List tournaments = await ApiService().getData(
        Endpoints.eventInfoHistory, await getBasicAuthHeader(),
        queryParams: days != null ? {"days": days.toString()} : {});

    return tournaments.cast();
  }

  Future<List<Map<String, dynamic>>> getEventLeaderboard(
      String eventId, String windowId) async {
    try {
      final List<int> leaderboardResponse = await ApiService().getData(
          Endpoints.eventLeaderboard, await getBasicAuthHeader(),
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
      if (e.runtimeType != ArchiveException) {
        talker.error('Error while getting event leaderboard: $e');
      }
      return [];
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> getEventScoringRules(
      String eventId, String windowId) async {
    try {
      final data = await ApiService().getData(
          Endpoints.eventScoringRules, await getBasicAuthHeader(),
          queryParams: {"eventId": eventId, "windowId": windowId});
      return (data as Map<String, dynamic>).map((key, value) =>
          MapEntry(key, (value as List).cast<Map<String, dynamic>>()));
    } catch (error) {
      talker.error(error);
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getEventPayoutTable(
      String eventId, String windowId) async {
    try {
      final List data = await ApiService().getData(
          Endpoints.eventPayoutTable, await getBasicAuthHeader(),
          queryParams: {"eventId": eventId, "windowId": windowId});
      return data.cast<Map<String, dynamic>>();
    } catch (error) {
      talker.error(error);
      return [];
    }
  }

  Future<Map<String, dynamic>> searchCosmetic(String id) async {
    try {
      final Map data = await ApiService().getData(
          Endpoints.cosmeticSearch, await getBasicAuthHeader(),
          queryParams: {"id": id});

      return (data["data"] as Map).cast<String, dynamic>();
    } catch (error) {
      talker.error(error);
      return {};
    }
  }

  Future<Map<String, dynamic>> getEventIdInfo(String id) async {
    try {
      final Map data = await ApiService().getData(
          Endpoints.eventIdInfo, await getBasicAuthHeader(),
          queryParams: {"id": id});

      return data.cast<String, dynamic>();
    } catch (error) {
      talker.error(error);
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> fetchEventLeaderboard(
      String eventId, String windowId) async {
    try {
      await ApiService().getData(
          Endpoints.fetchLeaderboard, await getBasicAuthHeader(),
          queryParams: {"eventId": eventId, "windowId": windowId});

      return await getEventLeaderboard(eventId, windowId);
    } catch (error) {
      talker.error(error);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchEventLeaderboardWithAccountIds(
      String eventId, String windowId, List<String> accountIds) async {
    try {
      await ApiService().postData(
          Endpoints.eventLeaderboard,
          jsonEncode({"accountIds": accountIds}),
          await getBasicAuthHeader(),
          Constants.dataJson,
          queryParams: {"eventId": eventId, "windowId": windowId});

      return await getEventLeaderboard(eventId, windowId);
    } catch (error) {
      talker.error(error);
      return [];
    }
  }

  Future<Map<String, dynamic>> getLeadeboardEntryInfo(
      int rank, String eventId, String windowId) async {
    final Map<String, dynamic> response = await ApiService().getData(
        Endpoints.eventEntryInfo, await getBasicAuthHeader(), queryParams: {
      "rank": rank.toString(),
      "eventId": eventId,
      "windowId": windowId
    });

    return response;
  }

  Future<List<Map<String, String>>> getRankedModes(
      {bool onlyActive = false}) async {
    try {
      final List<dynamic> result = await ApiService().getData(
          Endpoints.rankModeData,
          queryParams: {"onlyActive": onlyActive.toString()},
          await getBasicAuthHeader());

      return result.map<Map<String, String>>((item) {
        final map = item as Map<String, dynamic>;
        return map.map((key, value) => MapEntry(key, value.toString()));
      }).toList();
    } catch (error) {
      talker.error(error);
      return [];
    }
  }

  Future<void> changeGroupMetadata(String name, {int? id}) async {
    try {
      await ApiService().postData(
          Endpoints.changeGroupMetadata,
          jsonEncode({"name": name, "id": id.toString()}),
          await getBasicAuthHeader(),
          Constants.dataJson);
    } catch (error) {
      talker.error(error);
    }
  }

  Future<void> updateGroup(String accountId, int id) async {
    try {
      await ApiService().postData(
          Endpoints.changeGroup,
          jsonEncode({"accountId": accountId, "id": id}),
          await getBasicAuthHeader(),
          Constants.dataJson);
    } catch (error) {
      talker.error(error);
    }
  }

  Future<List<Map<String, dynamic>>> getGroups() async {
    try {
      final List<dynamic> result = await ApiService()
          .getData(Endpoints.getGroups, await getBasicAuthHeader());

      return result.cast<Map<String, dynamic>>();
    } catch (error) {
      talker.error(error);
      return [];
    }
  }
}
