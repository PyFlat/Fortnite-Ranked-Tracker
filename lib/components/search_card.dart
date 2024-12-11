import 'package:flutter/material.dart';
import 'package:fortnite_ranked_tracker/components/rank_card.dart';
import 'package:fortnite_ranked_tracker/constants/constants.dart';
import 'package:fortnite_ranked_tracker/core/database.dart';
import 'package:fortnite_ranked_tracker/core/rank_data.dart';
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
  String? nickName;
  String? accountAvatar;

  void refresh() {
    setState(() {});
  }

  Future<List<dynamic>> _fetchSelectedItem() async {
    List<dynamic> result =
        await RankService().getSingleProgress(widget.accountId);

    List<bool> activeRankingTypes =
        await DataBase().getPlayerTracking(widget.accountId);

    accountAvatar = (await RankService()
        .getAccountAvatarById(widget.accountId))[widget.accountId];

    nickName = await DataBase().getPlayerNickName(widget.accountId);

    final bool brActive = activeRankingTypes[0];
    final bool zbActive = activeRankingTypes[1];
    final bool rrActive = activeRankingTypes[2];
    final bool rlActive = activeRankingTypes[3];
    final bool rlzbActive = activeRankingTypes[4];
    final bool blActive = activeRankingTypes[5];

    List<dynamic> formattedResult = [
      null,
      null,
      null,
      null,
      null,
      null,
      [brActive, zbActive, rrActive, rlActive, rlzbActive, blActive]
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
      } else if (item["rankingType"] == "ranked_blastberry_build") {
        formattedResult[3] = formattedItem;
      } else if (item["rankingType"] == "ranked_blastberry_nobuild") {
        formattedResult[4] = formattedItem;
      } else if (item["rankingType"] == "ranked-feral") {
        formattedResult[5] = formattedItem;
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
          final rlData = snapshot.data?[3];
          final rlzbData = snapshot.data?[4];
          final blData = snapshot.data?[5];
          final active = snapshot.data?[6];
          return SizedBox(
            width: 350,
            height: 350,
            child: RankCard(
              displayName: widget.displayName,
              accountId: widget.accountId,
              accountAvatar: accountAvatar,
              nickName: nickName,
              searchCardKey: widget.key as GlobalKey,
              showMenu: false,
              showSwitches: true,
              battleRoyale: RankData(
                active: true,
                progressText: getStringValue(brData, 'RankProgressionText'),
                progress: getDoubleValue(brData, 'RankProgression'),
                lastChanged: getStringValue(brData, 'LastChanged'),
                rankImagePath: getImageAssetPath(brData),
                rank: getStringValue(brData, "Rank"),
                tracking: active[0],
              ),
              zeroBuild: RankData(
                active: true,
                progressText: getStringValue(zbData, 'RankProgressionText'),
                progress: getDoubleValue(zbData, 'RankProgression'),
                lastChanged: getStringValue(zbData, 'LastChanged'),
                rankImagePath: getImageAssetPath(zbData),
                rank: getStringValue(zbData, "Rank"),
                tracking: active[1],
              ),
              rocketRacing: RankData(
                active: true,
                progressText: getStringValue(rrData, 'RankProgressionText'),
                progress: getDoubleValue(rrData, 'RankProgression'),
                lastChanged: getStringValue(rrData, 'LastChanged'),
                rankImagePath: getImageAssetPath(rrData),
                rank: getStringValue(rrData, "Rank"),
                tracking: active[2],
              ),
              reload: RankData(
                active: true,
                progressText: getStringValue(rlData, 'RankProgressionText'),
                progress: getDoubleValue(rlData, 'RankProgression'),
                lastChanged: getStringValue(rlData, 'LastChanged'),
                rankImagePath: getImageAssetPath(rlData),
                rank: getStringValue(rlData, "Rank"),
                tracking: active[3],
              ),
              reloadZeroBuild: RankData(
                active: true,
                progressText: getStringValue(rlzbData, 'RankProgressionText'),
                progress: getDoubleValue(rlzbData, 'RankProgression'),
                lastChanged: getStringValue(rlzbData, 'LastChanged'),
                rankImagePath: getImageAssetPath(rlzbData),
                rank: getStringValue(rlzbData, "Rank"),
                tracking: active[4],
              ),
              ballistics: RankData(
                active: true,
                progressText: getStringValue(blData, 'RankProgressionText'),
                progress: getDoubleValue(blData, 'RankProgression'),
                lastChanged: getStringValue(blData, 'LastChanged'),
                rankImagePath: getImageAssetPath(blData),
                rank: getStringValue(blData, "Rank"),
                tracking: active[5],
              ),
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
