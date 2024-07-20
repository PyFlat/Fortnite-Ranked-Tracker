import 'package:flutter/material.dart';
import 'rank_card.dart';

class DashboardCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const DashboardCard({super.key, required this.item});

  Map<String, dynamic>? _getGameModeValues(String gameMode) {
    return item[gameMode] as Map<String, dynamic>?;
  }

  String? _getStringValue(Map<String, dynamic>? values, String key) {
    return values?[key] as String?;
  }

  double? _getDoubleValue(Map<String, dynamic>? values, String key) {
    return (values?[key] as num?)?.toDouble();
  }

  int? _getIntValue(Map<String, dynamic>? values, String key) {
    return (values?[key] as num?)?.toInt();
  }

  String? _getImageAssetPath(Map<String, dynamic>? values) {
    return 'assets/ranked-images/${_getStringValue(values, 'Rank')?.toLowerCase().replaceAll(" ", "")}.png';
  }

  @override
  Widget build(BuildContext context) {
    final displayName = item['DisplayName'] as String;

    final battleRoyaleValues = _getGameModeValues('Battle Royale');
    final zeroBuildValues = _getGameModeValues('Zero Build');
    final rocketRacingValues = _getGameModeValues('Rocket Racing');

    return RankCard(
      displayName: displayName,

      // Battle Royale
      battleRoyaleProgressText:
          _getStringValue(battleRoyaleValues, 'RankProgressionText'),
      battleRoyaleProgress:
          _getDoubleValue(battleRoyaleValues, 'RankProgression'),
      battleRoyaleLastProgress:
          _getStringValue(battleRoyaleValues, 'LastProgress'),
      battleRoyaleLastChanged:
          _getStringValue(battleRoyaleValues, 'LastChanged'),
      battleRoyaleDailyMatches:
          _getIntValue(battleRoyaleValues, 'DailyMatches'),
      battleRoyaleRankImagePath: _getImageAssetPath(battleRoyaleValues),
      battleRoyaleRank: _getStringValue(battleRoyaleValues, 'Rank'),
      battleRoyaleActive: battleRoyaleValues != null,

      // Zero Build
      zeroBuildProgressText:
          _getStringValue(zeroBuildValues, 'RankProgressionText'),
      zeroBuildProgress: _getDoubleValue(zeroBuildValues, 'RankProgression'),
      zeroBuildLastProgress: _getStringValue(zeroBuildValues, 'LastProgress'),
      zeroBuildLastChanged: _getStringValue(zeroBuildValues, 'LastChanged'),
      zeroBuildDailyMatches: _getIntValue(zeroBuildValues, 'DailyMatches'),
      zeroBuildRankImagePath: _getImageAssetPath(zeroBuildValues),
      zeroBuildRank: _getStringValue(zeroBuildValues, 'Rank'),
      zeroBuildActive: zeroBuildValues != null,

      // Rocket Racing
      rocketRacingProgressText:
          _getStringValue(rocketRacingValues, 'RankProgressionText'),
      rocketRacingProgress:
          _getDoubleValue(rocketRacingValues, 'RankProgression'),
      rocketRacingLastProgress:
          _getStringValue(rocketRacingValues, 'LastProgress'),
      rocketRacingLastChanged:
          _getStringValue(rocketRacingValues, 'LastChanged'),
      rocketRacingDailyMatches:
          _getIntValue(rocketRacingValues, 'DailyMatches'),
      rocketRacingRankImagePath: _getImageAssetPath(zeroBuildValues),
      rocketRacingRank: _getStringValue(rocketRacingValues, 'Rank'),
      rocketRacingActive: rocketRacingValues != null,
    );
  }
}
