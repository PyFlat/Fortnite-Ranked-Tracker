import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../constants/constants.dart';
import 'auth_provider.dart';
import 'api_service.dart';
import '../constants/endpoints.dart';
import 'rank_service.dart';

class TournamentService {
  bool _isInitialized = false;

  late AuthProvider authProvider;
  late Talker talker;
  late String directoryPath;

  TournamentService._();
  static final TournamentService _instance = TournamentService._();
  factory TournamentService() => _instance;

  Future<void> init(Talker talker, AuthProvider authProvider) async {
    if (!_isInitialized) {
      this.authProvider = authProvider;
      this.talker = talker;

      await _initializeTournamentStorage();

      _isInitialized = true;
    }
  }

  Future<void> _initializeTournamentStorage() async {
    Directory applicationStorage = await getApplicationSupportDirectory();
    directoryPath = join(applicationStorage.path, 'tournaments');
    await Directory(directoryPath).create(recursive: true);
  }

  String getBasicAuthHeader() {
    return "Bearer ${authProvider.accessToken}";
  }

  Future<List<Map<String, dynamic>>> getEvents() async {
    final List<Map<String, dynamic>> events = [];
    final parentDirectory = Directory(directoryPath);

    if (parentDirectory.existsSync()) {
      for (var folder in parentDirectory.listSync()) {
        if (folder is Directory) {
          final Map<String, dynamic> eventMap = {};
          eventMap['eventId'] = folder.path.split(Platform.pathSeparator).last;
          final Map<String, dynamic> regions = {};

          DateTime nextEventStartTime = DateTime(9999, 12, 31, 23, 59, 59);

          DateTime nextEventEndtime = DateTime(0000, 01, 01, 00, 00, 00);

          DateTime now = DateTime.now();

          for (var file in folder.listSync()) {
            if (file is File) {
              if (file.path.endsWith("info.json")) {
                var input = file.readAsStringSync();
                var map = jsonDecode(input);
                eventMap["title"] = map["title"];
                eventMap["imageUrl"] = map["imageUrl"];
                continue;
              }

              String regionName = "";

              if (Constants.regionRegex.hasMatch(file.path)) {
                RegExpMatch match =
                    Constants.regionRegex.firstMatch(file.path)!;
                regionName = match.namedGroup("region")!;
              }

              if (!regions.containsKey(regionName)) {
                regions[regionName] = [];
              }
              (regions[regionName] as List).add(file.path);

              var regionInput = await file.readAsBytes();
              List<int> decompressedBytes = gzip.decode(regionInput);

              String decompressedJsonString = utf8.decode(decompressedBytes);

              var regionData = jsonDecode(decompressedJsonString);

              DateTime regionBeginTime =
                  DateTime.parse(regionData["beginTime"]).toLocal();
              DateTime regionEndTime =
                  DateTime.parse(regionData["endTime"]).toLocal();

              if ((now.isAfter(regionBeginTime) &&
                      now.isBefore(regionEndTime)) ||
                  (regionBeginTime.isAfter(now) &&
                      regionBeginTime.isBefore(nextEventStartTime))) {
                nextEventStartTime = regionBeginTime;
                nextEventEndtime = regionEndTime;
              }
            }
          }
          eventMap["nextEventBeginTime"] = nextEventStartTime;
          eventMap["nextEventEndTime"] = nextEventEndtime;

          eventMap["regions"] = regions;

          events.add(eventMap);
        }
      }
      DateTime now = DateTime.now();

      events.sort((a, b) {
        DateTime beginA = a["nextEventBeginTime"] as DateTime;
        DateTime endA = a["nextEventEndTime"] as DateTime;
        DateTime beginB = b["nextEventBeginTime"] as DateTime;
        DateTime endB = b["nextEventEndTime"] as DateTime;

        bool aIsRunning = now.isAfter(beginA) && now.isBefore(endA);
        bool bIsRunning = now.isAfter(beginB) && now.isBefore(endB);

        if (aIsRunning && !bIsRunning) {
          return -1;
        } else if (!aIsRunning && bIsRunning) {
          return 1;
        } else {
          return beginA.compareTo(beginB);
        }
      });
    }

    return events;
  }

  Future<void> fetchEvents() async {
    final Map<String, dynamic> tournaments = await ApiService()
        .getData(Endpoints.eventData, getBasicAuthHeader(), pathParams: {
      "accountId": authProvider.accountId
    }, queryParams: {
      // "showPastEvents": ["true"] // Actiate if past events should be shown too
      // Missing an indicator from which Season which event is (Multiple Events Called 'Duo Cash Cup' lead to confusion)
    });

    final Map<String, dynamic> tournamentInfo =
        await ApiService().getData(Endpoints.eventInformation, "");

    for (var event in tournaments['events']) {
      var tournamentDisplayData =
          (tournamentInfo["tournament_info"]["tournaments"] as List).firstWhere(
        (tournament) =>
            tournament["tournament_display_id"] == event["displayDataId"],
        orElse: () => null,
      );

      tournamentDisplayData ??= (tournamentInfo.values.firstWhere((tdr) {
        if (tdr is! Map<String, dynamic>) {
          return false;
        }
        return tdr['tournament_info']?['tournament_display_id'] ==
            event['displayDataId'];
      }, orElse: () => null) as Map?)?['tournament_info'];

      if (tournamentDisplayData == null) {
        continue;
      }

      Directory eventFileDirectory =
          Directory(join(directoryPath, event["eventGroup"]));

      for (var window in event['eventWindows']) {
        final template = (tournaments['templates'] as List).firstWhere(
            (tt) => tt['eventTemplateId'] == window['eventTemplateId'],
            orElse: () => null);

        String eventCompleteId =
            "Fortnite:${event['eventId']}:${window['eventWindowId']}";

        String scoringRuleSetId =
            tournaments["scoreLocationScoringRuleSets"][eventCompleteId];

        if (template != null) {
          final RegExp regExp =
              RegExp(r"\w+Event(?<session>[\d]+)(Round(?<round>[\d]+))?\w+");

          int session;

          int round;

          if (regExp.hasMatch(window['eventWindowId'])) {
            RegExpMatch match = regExp.firstMatch(window['eventWindowId'])!;
            session = int.parse(match.namedGroup("session")!);
            var roundGroup = match.namedGroup("round");
            if (roundGroup != null) {
              round = int.parse(roundGroup);
            } else {
              round = 0;
            }
          } else {
            session = 1;
            round = 1;
          }

          File eventFile = File(
              "${eventFileDirectory.path}/${window["eventWindowId"]}.json.gz");

          if (!eventFile.existsSync()) {
            await eventFile.create(recursive: true);

            Map<String, dynamic> tournamentBasicData = {
              "eventId": event["eventId"],
              "eventGroup": event["eventGroup"],
              "windowId": window['eventWindowId'],
              "beginTime": window["beginTime"],
              "endTime": window["endTime"],
              "session": session,
              "round": round,
              "scoringRules": tournaments["scoringRuleSets"][scoringRuleSetId],
              "entries": List.filled(10000, {})
            };

            String jsonString = jsonEncode(tournamentBasicData);
            List<int> jsonBytes = utf8.encode(jsonString);
            List<int> compressedBytes = gzip.encode(jsonBytes);
            await eventFile.writeAsBytes(compressedBytes);
          }
        }
      }

      File infoFile = File("${eventFileDirectory.path}/info.json");

      if (!infoFile.existsSync()) {
        infoFile.createSync(recursive: true);

        Map<String, dynamic> tournamentInfoData = {
          "title": tournamentDisplayData["long_format_title"],
          "imageUrl": tournamentDisplayData["poster_front_image"],
        };

        String jsonString2 = jsonEncode(tournamentInfoData);

        await infoFile.writeAsString(jsonString2);
      }
    }
  }

  Future<Map<String, dynamic>> getEventLeaderboard(
      int page, Map<String, dynamic> tournamentWindow) async {
    List<Map<String, dynamic>> entries = [];
    Map<String, dynamic> result = {};
    if (page >= 0) {
      result = await ApiService().getData(
          Endpoints.eventLeaderboard, getBasicAuthHeader(),
          pathParams: {
            "eventId": tournamentWindow["eventId"],
            "eventWindowId": tournamentWindow["windowId"],
            "accountId": authProvider.accountId
          },
          queryParams: {
            "page": page.toString()
          });

      final allAccountIds = _extractAccountIds(result);

      final displayNames =
          await RankService().fetchByAccountId("", accountIds: allAccountIds);

      for (var entry in result["entries"]) {
        Map<String, String> accountMap = {};

        for (String accountId in (entry["teamAccountIds"] as List)) {
          var match = displayNames.firstWhere(
              (account) => account["accountId"] == accountId,
              orElse: () => {});

          if (match.isNotEmpty) {
            accountMap[accountId] = match["displayName"] ?? "Unknown";
          } else {
            accountMap[accountId] = "Unknown";
          }
        }

        Map<String, dynamic> newEntry = {
          "teamAccounts": accountMap,
          "pointsEarned": entry["pointsEarned"],
          "rank": entry["rank"],
          "sessionHistory": entry["sessionHistory"]
        };

        entries.add(newEntry);
      }
    }

    Directory eventFileDirectory =
        Directory(join(directoryPath, tournamentWindow["eventGroup"]));
    File eventFile = File(
        "${eventFileDirectory.path}/${tournamentWindow["windowId"]}.json.gz");

    List<int> compressedData = await eventFile.readAsBytes();

    List<int> decompressedBytes = gzip.decode(compressedData);

    String decompressedJsonString = utf8.decode(decompressedBytes);

    Map<String, dynamic> jsonContent = jsonDecode(decompressedJsonString);

    if (page >= 0) {
      jsonContent["totalPages"] = result["totalPages"];
      for (var entry in entries) {
        int rank = (entry['rank'] as int) - 1;

        if (rank >= 0 && rank < 10000) {
          (jsonContent["entries"] as List)[rank] = entry;
        }
      }

      decompressedJsonString = jsonEncode(jsonContent);

      List<int> jsonBytes = utf8.encode(decompressedJsonString);

      List<int> compressedBytes = gzip.encode(jsonBytes);

      await eventFile.writeAsBytes(compressedBytes);
    }

    return jsonContent;
  }

  List<String> _extractAccountIds(Map<String, dynamic> result) {
    return (result["entries"] as List).expand((entry) {
      return (entry["teamAccountIds"] as List<dynamic>)
          .map<String>((item) => item as String)
          .toList();
    }).toList();
  }
}
