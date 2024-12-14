import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../core/rank_data.dart';
import '../core/utils.dart';
import 'rank_card.dart';

class DashboardCard extends StatelessWidget {
  final Map<String, dynamic> item;

  final Color color;
  final int index;
  final Talker talker;

  const DashboardCard(
      {super.key,
      required this.item,
      required this.color,
      required this.index,
      required this.talker});

  RankData _buildRankData(Map<String, dynamic>? gameModeValues) {
    return RankData(
      progressText: getStringValue(gameModeValues, 'RankProgressionText'),
      progress: getDoubleValue(gameModeValues, 'RankProgression'),
      lastProgress: getStringValue(gameModeValues, 'LastProgress'),
      lastChanged: getStringValue(gameModeValues, 'LastChanged'),
      dailyMatches: getIntValue(gameModeValues, 'DailyMatches'),
      rankImagePath: getImageAssetPath(gameModeValues),
      rank: getStringValue(gameModeValues, 'Rank'),
      active: gameModeValues != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = item['DisplayName'] as String;
    final accountId = item["AccountId"] as String;
    final accountAvatar = item["AccountAvatar"];
    final nickName = item["NickName"];

    return RankCard(
      displayName: displayName,
      accountId: accountId,
      nickName: nickName,
      showMenu: true,
      showSwitches: false,
      accountAvatar: accountAvatar,
      color: color,
      initialIndex: index,
      talker: talker,
      rankModes: List.generate(
          modes.length,
          (index) =>
              _buildRankData(getGameModeValues(item, modes[index]['label']!))),
    );
  }
}
