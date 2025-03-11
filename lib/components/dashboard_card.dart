import 'package:flutter/material.dart';
import '../core/rank_data.dart';
import '../core/utils.dart';
import 'rank_card.dart';

class DashboardCard extends StatelessWidget {
  final Map<String, dynamic> item;

  final Color color;
  final int index;

  final List<Map<String, String>> modes;

  const DashboardCard(
      {super.key,
      required this.item,
      required this.color,
      required this.index,
      required this.modes});

  RankData _buildRankData(Map<String, dynamic>? gameModeValues) {
    String? lastChanged = getStringValue(gameModeValues, 'LastChanged');
    return RankData(
      progressText: getStringValue(gameModeValues, 'RankProgressionText'),
      progress: getDoubleValue(gameModeValues, 'RankProgression'),
      lastProgress: getStringValue(gameModeValues, 'LastProgress'),
      lastChanged: lastChanged != null ? formatDateTime(lastChanged) : null,
      dailyMatches: getIntValue(gameModeValues, 'DailyMatches'),
      rankImagePath: getImageAssetPath(gameModeValues),
      rank: getStringValue(gameModeValues, 'Rank'),
      oldRank: getStringValue(gameModeValues, 'OldRank'),
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
      nickName: nickName == "" ? null : nickName,
      showMenu: true,
      showSwitches: false,
      accountAvatar: accountAvatar,
      color: color,
      initialIndex: index,
      rankModes: List.generate(
          modes.length,
          (index) =>
              _buildRankData(getGameModeValues(item, modes[index]['label']!))),
    );
  }
}
