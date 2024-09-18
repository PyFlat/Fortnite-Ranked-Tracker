import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatsDisplay extends StatelessWidget {
  final Map<String, dynamic> entry;
  final List scoringRules;

  const StatsDisplay(
      {super.key, required this.entry, required this.scoringRules});

  @override
  Widget build(BuildContext context) {
    final sessionHistory = entry["sessionHistory"] as List;

    return Expanded(
      child: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildGeneralStats()),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sessionHistory.length,
                    itemBuilder: (context, index) {
                      final round = sessionHistory[index];
                      return _buildRoundCard(round, index + 1);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatRow(
          text: 'Wins: ${_getSessionHistoryStat("VICTORY_ROYALE_STAT", entry)}',
          icon: Icons.emoji_events_rounded,
          iconColor: Colors.amber,
        ),
        _buildStatRow(
          text: 'Rounds Played: ${(entry["sessionHistory"] as List).length}',
          icon: Icons.loop_rounded,
        ),
        _buildStatRow(
          text:
              'Kills Made: ${_getSessionHistoryStat("TEAM_ELIMS_STAT_INDEX", entry)}',
          icon: Icons.clear,
          iconColor: Colors.redAccent,
        ),
        _buildStatRow(
          text:
              'Avg Kills: ${(_getSessionHistoryStat("TEAM_ELIMS_STAT_INDEX", entry) / (entry["sessionHistory"] as List).length).toStringAsFixed(2)}',
          icon: Icons.hide_source_rounded,
        ),
        _buildStatRow(
          text:
              'Avg Time Alive: ${formatDuration((_getSessionHistoryStat("TIME_ALIVE_STAT", entry) / (entry["sessionHistory"] as List).length))}',
          icon: Icons.hourglass_top_rounded,
        ),
        _buildStatRow(
          text:
              'Avg Points: ${(entry["pointsEarned"] / (entry["sessionHistory"] as List).length).toStringAsFixed(2)}',
          icon: Icons.hotel_class_rounded,
        ),
      ],
    );
  }

  Widget _buildRoundCard(Map<String, dynamic> round, int roundNumber) {
    final String placement =
        '${round["trackedStats"]["PLACEMENT_STAT_INDEX"] ?? "N/A"}. Place';
    final int elims = round["trackedStats"]["TEAM_ELIMS_STAT_INDEX"] ?? 0;
    final String timeAlive =
        formatDuration(round["trackedStats"]["TIME_ALIVE_STAT"]);
    final int pointsEarned =
        calculatePoints(scoringRules, round["trackedStats"]);
    final String date =
        "${DateFormat(DateFormat.YEAR_ABBR_MONTH_WEEKDAY_DAY).format(DateTime.parse(round["endTime"]))} ${DateFormat(DateFormat.HOUR24_MINUTE).format(DateTime.parse(round["endTime"]))}";

    return Card(
      color: const Color(0xFF2C2F33),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      placement,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$elims Elims',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeAlive,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Points Earned:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                Text(
                  '$pointsEarned pts',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
                ),
                const Spacer(),
                Text("Round $roundNumber")
              ],
            ),
          ],
        ),
      ),
    );
  }

  int calculatePoints(List rules, Map<String, dynamic> stats) {
    num totalPoints = 0;

    for (var rule in rules) {
      final trackedStat = rule['trackedStat'];
      final matchRule = rule['matchRule'];
      final rewardTiers = rule['rewardTiers'] as List<dynamic>;

      if (stats.containsKey(trackedStat)) {
        final statValue = stats[trackedStat];
        for (var tier in rewardTiers) {
          final keyValue = tier['keyValue'];
          final pointsEarned = tier['pointsEarned'];
          final multiplicative = tier['multiplicative'];

          bool conditionMet = false;

          if (matchRule == 'lte') {
            conditionMet = statValue <= keyValue;
          } else if (matchRule == 'gte') {
            conditionMet = statValue >= keyValue;
          }

          if (conditionMet) {
            totalPoints +=
                multiplicative ? pointsEarned * statValue : pointsEarned;
          }
        }
      }
    }

    return totalPoints as int;
  }

  Widget _buildStatRow(
      {required String text, IconData? icon, Color? iconColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          if (icon != null)
            Icon(icon, color: iconColor ?? Colors.grey.shade300),
          if (icon != null) const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String formatDuration(num seconds) {
    int minutes = (seconds / 60).floor();
    int remainingSeconds = (seconds % 60).round();
    return '${minutes}m ${remainingSeconds}s';
  }

  int _getSessionHistoryStat(String key, Map<String, dynamic> entry) {
    final total = (entry["sessionHistory"] as List)
        .map((element) => element["trackedStats"][key] as int)
        .reduce((a, b) => a + b);
    return total;
  }
}
