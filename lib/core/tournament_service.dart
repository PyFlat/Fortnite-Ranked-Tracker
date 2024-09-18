import 'package:fortnite_ranked_tracker/constants/constants.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'auth_provider.dart';
import 'api_service.dart';
import '../constants/endpoints.dart';

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

      _isInitialized = true;
    }
  }

  String getBasicAuthHeader() {
    return "Bearer ${authProvider.accessToken}";
  }

  Future<List<Tournament>> getEventData() async {
    final Map<String, dynamic> tournaments = await ApiService()
        .getData(Endpoints.eventData, getBasicAuthHeader(), pathParams: {
      "accountId": authProvider.accountId
    }, queryParams: {
      // "showPastEvents": ["true"] // Actiate if past events should be shown too
      // Missing an indicator from which Season which event is (Multiple Events Called 'Duo Cash Cup' lead to confusion)
    });

    final Map<String, dynamic> tournamentInfo =
        await ApiService().getData(Endpoints.eventInformation, "");

    List<Tournament> constructedTournaments = [];

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

      List<TournamentWindowTemplate> templates = [];
      for (var window in event['eventWindows']) {
        final template = (tournaments['templates'] as List).firstWhere(
            (tt) => tt['eventTemplateId'] == window['eventTemplateId'],
            orElse: () => null);

        String eventCompleteId =
            "Fortnite:${event['eventId']}:${window['eventWindowId']}";

        String scoringRuleSetId =
            tournaments["scoreLocationScoringRuleSets"][eventCompleteId];

        if (template != null) {
          templates.add(
            TournamentWindowTemplate(
                windowId: window['eventWindowId'],
                eventId: event['eventId'],
                scoringRules: tournaments["scoringRuleSets"][scoringRuleSetId],
                title: tournamentDisplayData["long_format_title"],
                region: (event["regions"] as List).isNotEmpty
                    ? event["regions"][0]
                    : (event["eventId"] as String).split("_").last,
                countdownBeginTime:
                    DateTime.parse(window["countdownBeginTime"]),
                beginTime: DateTime.parse(window["beginTime"]),
                endTime: DateTime.parse(window["endTime"]),
                template: template),
          );
        }
      }

      bool tournamentExists = false;

      for (var x in constructedTournaments) {
        if (x.event["eventGroup"] == event["eventGroup"]) {
          x.regions.addAll({
            (event["regions"] as List).isNotEmpty
                ? event["regions"][0]
                : (event["eventId"] as String).split("_").last: templates
          });
          tournamentExists = true;
          break;
        }
      }

      if (!tournamentExists) {
        constructedTournaments.add(Tournament(
          event: event,
          region: (event["regions"] as List).isNotEmpty
              ? event["regions"][0]
              : (event["eventId"] as String).split("_").last,
          title: tournamentDisplayData["long_format_title"],
          posterImageUrl: tournamentDisplayData["poster_front_image"],
          templates: templates,
        ));
      }
    }

    return constructedTournaments;
  }

  Future<Map<String, dynamic>> getEventLeaderboard(
      int page, TournamentWindowTemplate tournamentWindow) async {
    final Map<String, dynamic> result = await ApiService()
        .getData(Endpoints.eventLeaderboard, getBasicAuthHeader(), pathParams: {
      "eventId": tournamentWindow.eventId,
      "eventWindowId": tournamentWindow.windowId,
      "accountId": authProvider.accountId
    }, queryParams: {
      "page": page.toString()
    });
    return result;
  }
}

class TournamentWindowTemplate {
  final String windowId;
  final String eventId;
  final List scoringRules;
  final String title;
  final String region;
  final DateTime countdownBeginTime;
  DateTime beginTime;
  DateTime endTime;
  final Map<String, dynamic> template;

  late int session;
  late int round;

  late String regionTrivial;

  TournamentWindowTemplate(
      {required this.windowId,
      required this.eventId,
      required this.scoringRules,
      required this.title,
      required this.region,
      required this.countdownBeginTime,
      required this.beginTime,
      required this.endTime,
      required this.template}) {
    regionTrivial = Constants.regions[region]!;
    beginTime = beginTime.toLocal();
    endTime = endTime.toLocal();

    final RegExp regExp =
        RegExp(r"\w+Event(?<session>[\d]+)(Round(?<round>[\d]+))?\w+");

    if (regExp.hasMatch(windowId)) {
      RegExpMatch match = regExp.firstMatch(windowId)!;
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
  }
}

class Tournament {
  final Map<String, dynamic> event;
  Map<String, List<TournamentWindowTemplate>> regions = {};
  final String title;
  final String posterImageUrl;

  Tournament({
    required this.event,
    required String region,
    required this.title,
    required this.posterImageUrl,
    required List<TournamentWindowTemplate> templates,
  }) {
    regions.addAll({region: templates});
  }
}
