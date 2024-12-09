import 'package:flutter/material.dart';
import '../core/utils.dart';
import 'rank_card.dart';

class DashboardCard extends StatelessWidget {
  final Map<String, dynamic> item;

  final Color color;
  final int index;

  const DashboardCard(
      {super.key,
      required this.item,
      required this.color,
      required this.index});

  @override
  Widget build(BuildContext context) {
    final displayName = item['DisplayName'] as String;
    final accountId = item["AccountId"] as String;
    final accountAvatar = item["AccountAvatar"];
    final nickName = item["NickName"];

    final battleRoyaleValues = getGameModeValues(item, 'Battle Royale');
    final zeroBuildValues = getGameModeValues(item, 'Zero Build');
    final rocketRacingValues = getGameModeValues(item, 'Rocket Racing');
    final reloadValues = getGameModeValues(item, 'Reload');
    final reloadZeroBuildValues = getGameModeValues(item, 'Reload Zero Build');

    String? battleRoyaleLastChanged =
        getStringValue(battleRoyaleValues, 'LastChanged');
    String? zeroBuildLastChanged =
        getStringValue(zeroBuildValues, 'LastChanged');
    String? rocketRacingLastChanged =
        getStringValue(rocketRacingValues, 'LastChanged');
    String? reloadLastChanged = getStringValue(reloadValues, 'LastChanged');
    String? reloadZeroBuildLastChanged =
        getStringValue(reloadZeroBuildValues, 'LastChanged');

    battleRoyaleLastChanged = battleRoyaleLastChanged != null
        ? formatDateTime(battleRoyaleLastChanged)
        : null;
    zeroBuildLastChanged = zeroBuildLastChanged != null
        ? formatDateTime(zeroBuildLastChanged)
        : null;
    rocketRacingLastChanged = rocketRacingLastChanged != null
        ? formatDateTime(rocketRacingLastChanged)
        : null;
    reloadLastChanged =
        reloadLastChanged != null ? formatDateTime(reloadLastChanged) : null;
    reloadZeroBuildLastChanged = reloadZeroBuildLastChanged != null
        ? formatDateTime(reloadZeroBuildLastChanged)
        : null;

    return RankCard(
      displayName: displayName,
      accountId: accountId,
      nickName: nickName == "" ? null : nickName,
      showMenu: true,
      showSwitches: false,
      accountAvatar: accountAvatar,

      color: color,
      initialIndex: index,

      // Battle Royale
      battleRoyaleProgressText:
          getStringValue(battleRoyaleValues, 'RankProgressionText'),
      battleRoyaleProgress:
          getDoubleValue(battleRoyaleValues, 'RankProgression'),
      battleRoyaleLastProgress:
          getStringValue(battleRoyaleValues, 'LastProgress'),
      battleRoyaleLastChanged: battleRoyaleLastChanged,
      battleRoyaleDailyMatches: getIntValue(battleRoyaleValues, 'DailyMatches'),
      battleRoyaleRankImagePath: getImageAssetPath(battleRoyaleValues),
      battleRoyaleRank: getStringValue(battleRoyaleValues, 'Rank'),
      battleRoyaleActive: battleRoyaleValues != null,

      // Zero Build
      zeroBuildProgressText:
          getStringValue(zeroBuildValues, 'RankProgressionText'),
      zeroBuildProgress: getDoubleValue(zeroBuildValues, 'RankProgression'),
      zeroBuildLastProgress: getStringValue(zeroBuildValues, 'LastProgress'),
      zeroBuildLastChanged: zeroBuildLastChanged,
      zeroBuildDailyMatches: getIntValue(zeroBuildValues, 'DailyMatches'),
      zeroBuildRankImagePath: getImageAssetPath(zeroBuildValues),
      zeroBuildRank: getStringValue(zeroBuildValues, 'Rank'),
      zeroBuildActive: zeroBuildValues != null,

      // Rocket Racing
      rocketRacingProgressText:
          getStringValue(rocketRacingValues, 'RankProgressionText'),
      rocketRacingProgress:
          getDoubleValue(rocketRacingValues, 'RankProgression'),
      rocketRacingLastProgress:
          getStringValue(rocketRacingValues, 'LastProgress'),
      rocketRacingLastChanged: rocketRacingLastChanged,
      rocketRacingDailyMatches: getIntValue(rocketRacingValues, 'DailyMatches'),
      rocketRacingRankImagePath: getImageAssetPath(rocketRacingValues),
      rocketRacingRank: getStringValue(rocketRacingValues, 'Rank'),
      rocketRacingActive: rocketRacingValues != null,

      // Reload
      reloadProgressText: getStringValue(reloadValues, 'RankProgressionText'),
      reloadProgress: getDoubleValue(reloadValues, 'RankProgression'),
      reloadLastProgress: getStringValue(reloadValues, 'LastProgress'),
      reloadLastChanged: reloadLastChanged,
      reloadDailyMatches: getIntValue(reloadValues, 'DailyMatches'),
      reloadRankImagePath: getImageAssetPath(reloadValues),
      reloadRank: getStringValue(reloadValues, 'Rank'),
      reloadActive: reloadValues != null,

      // Reload Zero Build
      reloadZeroBuildProgressText:
          getStringValue(reloadZeroBuildValues, 'RankProgressionText'),
      reloadZeroBuildProgress:
          getDoubleValue(reloadZeroBuildValues, 'RankProgression'),
      reloadZeroBuildLastProgress:
          getStringValue(reloadZeroBuildValues, 'LastProgress'),
      reloadZeroBuildLastChanged: reloadZeroBuildLastChanged,
      reloadZeroBuildDailyMatches:
          getIntValue(reloadZeroBuildValues, 'DailyMatches'),
      reloadZeroBuildRankImagePath: getImageAssetPath(reloadZeroBuildValues),
      reloadZeroBuildRank: getStringValue(reloadZeroBuildValues, 'Rank'),
      reloadZeroBuildActive: reloadZeroBuildValues != null,
    );
  }
}
