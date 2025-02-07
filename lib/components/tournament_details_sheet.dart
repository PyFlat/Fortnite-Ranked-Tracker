import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fortnite_ranked_tracker/components/payout_table_widget.dart';
import 'package:fortnite_ranked_tracker/components/scoring_rules_widget.dart';
import 'package:intl/intl.dart';

class TournamentDetailsSheet extends StatefulWidget {
  final String regionName;
  final String title;
  final String windowName;
  final String beginTime;
  final String endTime;
  final String id;

  final bool isCumulative;
  final bool showCumulative;

  final List<Map<String, dynamic>> scoringRules;
  final List<Map<String, dynamic>> allLeaderboardData;

  final String eventId;
  final String windowId;

  const TournamentDetailsSheet(
      {super.key,
      required this.regionName,
      required this.title,
      required this.windowName,
      required this.beginTime,
      required this.endTime,
      required this.id,
      required this.isCumulative,
      required this.showCumulative,
      required this.scoringRules,
      required this.allLeaderboardData,
      required this.eventId,
      required this.windowId});

  @override
  State<TournamentDetailsSheet> createState() => _TournamentDetailsSheetState();
}

class _TournamentDetailsSheetState extends State<TournamentDetailsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showCheckmark = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String formatDateTime(String isoString) {
    final dateTime = DateTime.parse(isoString).toLocal();
    return DateFormat('dd.MM.yyyy - HH:mm').format(dateTime);
  }

  Widget _buildIcon(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(8),
      child: Icon(icon, color: color, size: 16),
    );
  }

  Widget buildScoringRules(List<Map<String, dynamic>> scoringRules) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: scoringRules.map<Widget>((rule) {
        if (rule['trackedStat'] == 'PLACEMENT_STAT_INDEX') {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Placement Rewards:",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                ...rule['rewardTiers'].map<Widget>((tier) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      "Top ${tier['keyValue']} - ${tier['pointsEarned']} points",
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        } else if (rule['trackedStat'] == 'TEAM_ELIMS_STAT_INDEX') {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Elimination Rewards:",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                Text(
                  "For each elimination: ${rule['rewardTiers'][0]['pointsEarned']} points",
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          );
        }
        return SizedBox();
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2A3A),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  label: const Text("Event ID"),
                  icon: _showCheckmark
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.copy, size: 20, color: Colors.grey),
                  onPressed: () async {
                    Clipboard.setData(ClipboardData(text: widget.id));
                    setState(() {
                      _showCheckmark = true;
                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) {
                          setState(() {
                            _showCheckmark = false;
                          });
                        }
                      });
                    });
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Divider(),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildIcon(Icons.event_note, Colors.red),
                    SizedBox(
                      width: 14,
                    ),
                    Expanded(
                      child: Text(
                        "Session: ${widget.windowName}",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 14,
                    ),
                    IconButton(
                        onPressed: () {
                          Navigator.pop(context, 2);
                        },
                        icon: Icon(
                          Icons.edit,
                          color: Colors.white,
                        )),
                  ],
                ),
                if (widget.showCumulative) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Row(
                        children: [
                          _buildIcon(Icons.bar_chart, Colors.yellow),
                          const SizedBox(width: 14),
                          Text(
                            "Cumulative",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        width: 14,
                      ),
                      CustomSwitch(
                          value: widget.isCumulative,
                          onChanged: (value) {
                            Navigator.pop(context, widget.isCumulative ? 1 : 0);
                          }),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildIcon(Icons.location_on, Colors.blue),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Region: ${widget.regionName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildIcon(Icons.calendar_today, Colors.green),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start: ${formatDateTime(widget.beginTime)}',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'End: ${formatDateTime(widget.endTime)}',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(text: "Rules"),
                Tab(text: "Prices"),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(
                      child: ScoringRulesWidget(
                          scoringRules: widget.scoringRules)),
                  SingleChildScrollView(
                      child: PayoutTableWidget(
                    eventId: widget.eventId,
                    windowId: widget.windowId,
                    allLeaderboardData: widget.allLeaderboardData,
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomSwitch({super.key, required this.value, required this.onChanged});

  @override
  CustomSwitchState createState() => CustomSwitchState();
}

class CustomSwitchState extends State<CustomSwitch> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),
      child: MouseRegion(
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: Container(
          width: 50,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: widget.value ? Colors.green : Colors.red,
          ),
          child: Padding(
            padding: EdgeInsets.all(5),
            child: AnimatedAlign(
              duration: Duration(milliseconds: 200),
              alignment:
                  widget.value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: isHovered
                      ? [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: .75),
                              blurRadius: 8),
                        ]
                      : [],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
