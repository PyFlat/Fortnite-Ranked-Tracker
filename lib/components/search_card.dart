import 'package:flutter/material.dart';
import 'package:fortnite_ranked_tracker/components/rank_card.dart';
import 'package:fortnite_ranked_tracker/constants/constants.dart';
import 'package:fortnite_ranked_tracker/core/database.dart';
import 'package:fortnite_ranked_tracker/core/utils.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../core/rank_service.dart';

class SearchCard extends StatefulWidget {
  final String accountId;
  final String displayName;
  final Talker talker;
  const SearchCard(
      {super.key,
      required this.accountId,
      required this.displayName,
      required this.talker});

  @override
  SearchCardState createState() => SearchCardState();
}

class SearchCardState extends State<SearchCard> {
  Future<List<dynamic>> _fetchSelectedItem() async {
    List<dynamic> result =
        await RankService().getSingleProgress(widget.accountId);

    List<bool> activeRankingTypes =
        await DataBase().getPlayerTracking(widget.accountId);

    final bool brActive = activeRankingTypes[0];
    final bool zbActive = activeRankingTypes[1];
    final bool rrActive = activeRankingTypes[2];

    List<dynamic> formattedResult = [
      null,
      null,
      null,
      [brActive, zbActive, rrActive]
    ];
    for (dynamic item in result) {
      String progressText = item["currentDivision"] == 17
          ? '#${item["currentPlayerRanking"]}'
          : "${(item["promotionProgress"] * 100 as double).round()}%";

      Map<String, dynamic> formattedItem;

      if (item["lastUpdated"] == "1970-01-01T00:00:00Z") {
        formattedItem = {
          "Rank": "Unranked",
          "LastChanged": null,
          "RankProgression": null,
          "RankProgressionText": null
        };
      } else {
        formattedItem = {
          "Rank": Constants.ranks[item["currentDivision"]],
          "LastChanged": formatDateTime(item["lastUpdated"]),
          "RankProgression": item["promotionProgress"],
          "RankProgressionText": progressText
        };
      }

      if (item["rankingType"] == "ranked-br") {
        formattedResult[0] = formattedItem;
      } else if (item["rankingType"] == "ranked-zb") {
        formattedResult[1] = formattedItem;
      } else if (item["rankingType"] == "delmar-competitive") {
        formattedResult[2] = formattedItem;
      }
    }
    return formattedResult;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _fetchSelectedItem(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          final brData = snapshot.data?[0];
          final zbData = snapshot.data?[1];
          final rrData = snapshot.data?[2];
          final active = snapshot.data?[3];
          return SizedBox(
            width: 350,
            height: 350,
            child: RankCard(
              displayName: widget.displayName,
              accountId: widget.accountId,
              showMenu: false,
              showSwitches: true,
              battleRoyaleActive: true,
              battleRoyaleProgressText:
                  getStringValue(brData, 'RankProgressionText'),
              battleRoyaleProgress: getDoubleValue(brData, 'RankProgression'),
              battleRoyaleLastChanged: getStringValue(brData, 'LastChanged'),
              battleRoyaleRankImagePath: getImageAssetPath(brData),
              battleRoyaleRank: getStringValue(brData, "Rank"),
              battleRoyaleTracking: active[0],
              zeroBuildActive: true,
              zeroBuildProgressText:
                  getStringValue(zbData, 'RankProgressionText'),
              zeroBuildProgress: getDoubleValue(zbData, 'RankProgression'),
              zeroBuildLastChanged: getStringValue(zbData, 'LastChanged'),
              zeroBuildRankImagePath: getImageAssetPath(zbData),
              zeroBuildRank: getStringValue(zbData, "Rank"),
              zeroBuildTracking: active[1],
              rocketRacingActive: true,
              rocketRacingProgressText:
                  getStringValue(rrData, 'RankProgressionText'),
              rocketRacingProgress: getDoubleValue(rrData, 'RankProgression'),
              rocketRacingLastChanged: getStringValue(rrData, 'LastChanged'),
              rocketRacingRankImagePath: getImageAssetPath(rrData),
              rocketRacingRank: getStringValue(rrData, "Rank"),
              rocketRacingTracking: active[2],
              talker: widget.talker,
            ),
          );
        } else {
          return const Text('No data available');
        }
      },
    );
  }
}
