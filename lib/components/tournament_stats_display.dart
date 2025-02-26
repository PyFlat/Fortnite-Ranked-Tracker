import 'package:flutter/material.dart';
import 'package:fortnite_ranked_tracker/core/rank_service.dart';
import 'package:intl/intl.dart';

class StatsDisplay extends StatefulWidget {
  final Map<String, dynamic> entry;
  final Function(String, String) openUser;
  final Map<String, dynamic> eventWindow;
  final Map<String, List<Map<String, dynamic>>> scoringRules;

  const StatsDisplay(
      {super.key,
      required this.entry,
      required this.eventWindow,
      required this.scoringRules,
      required this.openUser});

  @override
  State<StatsDisplay> createState() => _StatsDisplayState();
}

class _StatsDisplayState extends State<StatsDisplay> {
  Future<Map<String, dynamic>>? _initializationFuture;

  @override
  void initState() {
    _initializationFuture = getLeaderboardEntryInfo();
    super.initState();
  }

  Future<Map<String, dynamic>> getLeaderboardEntryInfo() async {
    final data = await RankService().getLeadeboardEntryInfo(
        widget.entry["rank"],
        widget.eventWindow["eventId"],
        widget.eventWindow["windowId"]);

    return data;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          final data = snapshot.data;
          final sessionHistory = data!["sessions"] as List;
          sessionHistory.sort((a, b) => DateTime.parse(a["endTime"])
                  .isBefore(DateTime.parse(b["endTime"]))
              ? -1
              : 1);

          return Expanded(
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildGeneralStats(data)),
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
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildGeneralStats(data) {
    Map<String, dynamic> teamAccounts =
        Map<String, dynamic>.from(data["accounts"]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...teamAccounts.entries.toList().asMap().entries.map((entry) {
          int index = entry.key;
          var mapEntry = entry.value;
          String accountId = mapEntry.key;
          String name = mapEntry.value;

          int lastIndex = teamAccounts.entries.length - 1;

          return Card(
            margin: EdgeInsets.only(bottom: index != lastIndex ? 8.0 : 0.0),
            color: const Color(0xFF2C2F33),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.open_in_new_rounded,
                    color: Colors.deepPurple),
                onPressed: () {
                  widget.openUser(name, accountId);
                },
              ),
              onTap: () {
                widget.openUser(name, accountId);
              },
            ),
          );
        }),
        const Divider(),
        _buildStatRow(
          text: 'Wins: ${widget.entry["victories"]}',
          icon: Icons.emoji_events_rounded,
          iconColor: Colors.amber,
        ),
        _buildStatRow(
          text: 'Rounds Played: ${widget.entry["matches"]}',
          icon: Icons.loop_rounded,
        ),
        _buildStatRow(
          text: 'Kills Made: ${widget.entry["elims"]}',
          icon: Icons.clear,
          iconColor: Colors.redAccent,
        ),
        _buildStatRow(
          text:
              'Avg Kills: ${(widget.entry["elims"] / widget.entry["matches"]).toStringAsFixed(2)}',
          icon: Icons.hide_source_rounded,
        ),
        _buildStatRow(
          text:
              'Avg Time Alive: ${formatDuration((_getSessionHistoryStat("TIME_ALIVE_STAT", data) / widget.entry["matches"]))}',
          icon: Icons.hourglass_top_rounded,
        ),
        _buildStatRow(
          text:
              'Avg Points: ${(widget.entry["points"] / widget.entry["matches"]).toStringAsFixed(2)}',
          icon: Icons.hotel_class_rounded,
        ),
        _buildStatRow(
          text:
              'Avg Place: ${(_getSessionHistoryStat("PLACEMENT_STAT_INDEX", data) / widget.entry["matches"]).toStringAsFixed(2)}',
          icon: Icons.leaderboard_rounded,
        ),
      ],
    );
  }

  Widget _buildRoundCard(Map<String, dynamic> session, int roundNumber) {
    final int placement = session["PLACEMENT_STAT_INDEX"] ?? -1;
    final String placementString =
        placement > 0 ? '$placement. Place' : 'No Placement';
    final int elims = session["TEAM_ELIMS_STAT_INDEX"] ?? 0;
    final String timeAlive = formatDuration(session["TIME_ALIVE_STAT"]);
    final String date =
        "${DateFormat(DateFormat.YEAR_ABBR_MONTH_WEEKDAY_DAY).format(DateTime.parse(session["endTime"]).toLocal())} ${DateFormat(DateFormat.HOUR24_MINUTE).format(DateTime.parse(session["endTime"]).toLocal())}";

    Color borderColor;
    switch (placement) {
      case 1:
        borderColor = Colors.amber;
        break;
      case 2:
        borderColor = Colors.grey;
        break;
      case 3:
        borderColor = const Color(0xFFCD7F32);
        break;
      default:
        borderColor = Colors.transparent;
    }

    return Card(
      color: (session["scored"] ?? true)
          ? const Color(0xFF2C2F33)
          : const Color(0xFF7E8287),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor, width: 2),
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
                      placementString,
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
                  '${calculatePoints(session)} pts',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
                ),
                const Spacer(),
                Text("Round $roundNumber"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int calculatePoints(Map<String, dynamic> stats) {
    num totalPoints = 0;

    for (var rule in widget.scoringRules[stats["tournamentId"]]!) {
      final trackedStat = rule['trackedStat'];
      final matchRule = rule['matchRule'];

      if (stats.containsKey(trackedStat)) {
        final statValue = stats[trackedStat];

        final rewardTiers = rule["rewardTiers"];

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
        color: const Color(0xFF2C2F33),
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
    final total = (entry["sessions"] as List)
        .map((element) => element[key] as int)
        .reduce((a, b) => a + b);
    return total;
  }
}
