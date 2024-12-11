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
    final ballisticsValues = getGameModeValues(item, 'Ballistics');

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
      battleRoyale: RankData(
        progressText: getStringValue(battleRoyaleValues, 'RankProgressionText'),
        progress: getDoubleValue(battleRoyaleValues, 'RankProgression'),
        lastProgress: getStringValue(battleRoyaleValues, 'LastProgress'),
        lastChanged: getStringValue(battleRoyaleValues, 'LastChanged'),
        dailyMatches: getIntValue(battleRoyaleValues, 'DailyMatches'),
        rankImagePath: getImageAssetPath(battleRoyaleValues),
        rank: getStringValue(battleRoyaleValues, 'Rank'),
        active: battleRoyaleValues != null,
      ),
      zeroBuild: RankData(
        progressText: getStringValue(zeroBuildValues, 'RankProgressionText'),
        progress: getDoubleValue(zeroBuildValues, 'RankProgression'),
        lastProgress: getStringValue(zeroBuildValues, 'LastProgress'),
        lastChanged: getStringValue(zeroBuildValues, 'LastChanged'),
        dailyMatches: getIntValue(zeroBuildValues, 'DailyMatches'),
        rankImagePath: getImageAssetPath(zeroBuildValues),
        rank: getStringValue(zeroBuildValues, 'Rank'),
        active: zeroBuildValues != null,
      ),
      rocketRacing: RankData(
        progressText: getStringValue(rocketRacingValues, 'RankProgressionText'),
        progress: getDoubleValue(rocketRacingValues, 'RankProgression'),
        lastProgress: getStringValue(rocketRacingValues, 'LastProgress'),
        lastChanged: getStringValue(rocketRacingValues, 'LastChanged'),
        dailyMatches: getIntValue(rocketRacingValues, 'DailyMatches'),
        rankImagePath: getImageAssetPath(rocketRacingValues),
        rank: getStringValue(rocketRacingValues, 'Rank'),
        active: rocketRacingValues != null,
      ),
      reload: RankData(
        progressText: getStringValue(reloadValues, 'RankProgressionText'),
        progress: getDoubleValue(reloadValues, 'RankProgression'),
        lastProgress: getStringValue(reloadValues, 'LastProgress'),
        lastChanged: getStringValue(reloadValues, 'LastChanged'),
        dailyMatches: getIntValue(reloadValues, 'DailyMatches'),
        rankImagePath: getImageAssetPath(reloadValues),
        rank: getStringValue(reloadValues, 'Rank'),
        active: reloadValues != null,
      ),
      reloadZeroBuild: RankData(
        progressText:
            getStringValue(reloadZeroBuildValues, 'RankProgressionText'),
        progress: getDoubleValue(reloadZeroBuildValues, 'RankProgression'),
        lastProgress: getStringValue(reloadZeroBuildValues, 'LastProgress'),
        lastChanged: getStringValue(reloadZeroBuildValues, 'LastChanged'),
        dailyMatches: getIntValue(reloadZeroBuildValues, 'DailyMatches'),
        rankImagePath: getImageAssetPath(reloadZeroBuildValues),
        rank: getStringValue(reloadZeroBuildValues, 'Rank'),
        active: reloadZeroBuildValues != null,
      ),
      ballistics: RankData(
        progressText: getStringValue(ballisticsValues, 'RankProgressionText'),
        progress: getDoubleValue(ballisticsValues, 'RankProgression'),
        lastProgress: getStringValue(ballisticsValues, 'LastProgress'),
        lastChanged: getStringValue(ballisticsValues, 'LastChanged'),
        dailyMatches: getIntValue(ballisticsValues, 'DailyMatches'),
        rankImagePath: getImageAssetPath(ballisticsValues),
        rank: getStringValue(ballisticsValues, 'Rank'),
        active: ballisticsValues != null,
      ),
    );
  }
}
