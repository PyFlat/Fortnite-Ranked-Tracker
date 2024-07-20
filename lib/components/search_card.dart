import 'package:flutter/material.dart';
import 'package:fortnite_ranked_tracker/components/rank_card.dart';
import 'package:fortnite_ranked_tracker/constants/constants.dart';
import 'package:fortnite_ranked_tracker/core/utils.dart';

import '../core/rank_service.dart';

class SearchCard extends StatefulWidget {
  final accountId;
  final displayName;
  const SearchCard(
      {super.key, required this.accountId, required this.displayName});

  @override
  _SearchCardState createState() => _SearchCardState();
}

class _SearchCardState extends State<SearchCard> {
  Future<List<dynamic>> _fetchSelectedItem() async {
    List<dynamic> result =
        await RankService().getSingleProgress(widget.accountId);

    List<dynamic> formattedResult = [null, null, null];
    for (dynamic item in result) {
      String progressText = item["currentDivision"] == 17
          ? '#${item["currentPlayerRanking"]}'
          : "${(item["promotionProgress"] * 100 as double).round()}%";

      final formattedItem = {
        "Rank": Constants.ranks[item["currentDivision"]],
        "LastChanged": formatDateTime(item["lastUpdated"]),
        "RankProgression": item["promotionProgress"],
        "RankProgressionText": progressText
      };
      if (item["rankingType"] == "ranked-br") {
        formattedResult[0] = formattedItem;
      } else if (item["rankingType"] == "ranked-zb") {
        formattedResult[0] = formattedItem;
      } else if (item["rankingType"] == "delmar-competitive") {
        formattedResult[0] = formattedItem;
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
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          final brData = snapshot.data?[0];
          final zbData = snapshot.data?[1];
          final rrData = snapshot.data?[2];
          return SizedBox(
            width: 350,
            height: 350,
            child: RankCard(
                displayName: widget.displayName ?? "",
                battleRoyaleActive: true,
                battleRoyaleProgressText:
                    getStringValue(brData, 'RankProgressionText'),
                battleRoyaleProgress: getDoubleValue(brData, 'RankProgression'),
                battleRoyaleLastChanged: getStringValue(brData, 'LastChanged'),
                battleRoyaleRankImagePath: getImageAssetPath(brData),
                battleRoyaleRank: getStringValue(brData, "Rank"),
                zeroBuildActive: true,
                rocketRacingActive: true),
          ); //MyCard(item: snapshot.data!);
        } else {
          return Text('No data available');
        }
      },
    );
  }
}
