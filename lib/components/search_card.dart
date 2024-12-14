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

    List<dynamic> formattedResult = [
      activeRankingTypes,
      ...List.filled(activeRankingTypes.length, null)
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

      final types = modes.map((mode) => mode['type']).toList();

      formattedResult[types.indexOf(item["rankingType"]) + 1] = formattedItem;
    }
    return formattedResult;
  }

  RankData _buildRankData(dynamic data, dynamic tracking) {
    return RankData(
      active: true,
      progressText: getStringValue(data, 'RankProgressionText'),
      progress: getDoubleValue(data, 'RankProgression'),
      lastChanged: getStringValue(data, 'LastChanged'),
      rankImagePath: getImageAssetPath(data),
      rank: getStringValue(data, "Rank"),
      tracking: tracking,
    );
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
          final snapshotData = snapshot.data ?? [];

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
              rankModes: List.generate(
                modes.length,
                (index) => _buildRankData(
                  snapshotData.length > index + 1
                      ? snapshotData[index + 1]
                      : null,
                  snapshotData.isNotEmpty && snapshotData[0] != null
                      ? snapshotData[0][index]
                      : null,
                ),
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
