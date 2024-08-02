import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fortnite_ranked_tracker/core/database.dart';
import 'package:fortnite_ranked_tracker/core/rank_service.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../screens/search_screen.dart';

class RankCard extends StatefulWidget {
  final String displayName;
  final String? accountId;
  final bool showMenu;
  final bool showSwitches;
  final String? accountAvatar;

  final String? battleRoyaleProgressText;
  final double? battleRoyaleProgress;
  final String? battleRoyaleLastProgress;
  final String? battleRoyaleLastChanged;
  final int? battleRoyaleDailyMatches;
  final String? battleRoyaleRankImagePath;
  final String? battleRoyaleRank;
  final bool battleRoyaleActive;
  final bool? battleRoyaleTracking;

  final String? zeroBuildProgressText;
  final double? zeroBuildProgress;
  final String? zeroBuildLastProgress;
  final String? zeroBuildLastChanged;
  final int? zeroBuildDailyMatches;
  final String? zeroBuildRankImagePath;
  final String? zeroBuildRank;
  final bool zeroBuildActive;
  final bool? zeroBuildTracking;

  final String? rocketRacingProgressText;
  final double? rocketRacingProgress;
  final String? rocketRacingLastProgress;
  final String? rocketRacingLastChanged;
  final int? rocketRacingDailyMatches;
  final String? rocketRacingRankImagePath;
  final String? rocketRacingRank;
  final bool rocketRacingActive;
  final bool? rocketRacingTracking;

  final Color? color;

  final int? initialIndex;

  const RankCard({
    this.color = Colors.black26,
    this.initialIndex = 0,
    super.key,
    required this.displayName,
    this.accountId,
    this.accountAvatar,
    required this.showMenu,
    required this.showSwitches,
    this.battleRoyaleProgressText,
    this.battleRoyaleProgress,
    this.battleRoyaleLastProgress,
    this.battleRoyaleLastChanged,
    this.battleRoyaleDailyMatches,
    this.battleRoyaleRankImagePath,
    this.battleRoyaleRank,
    required this.battleRoyaleActive,
    this.battleRoyaleTracking,
    this.zeroBuildProgressText,
    this.zeroBuildProgress,
    this.zeroBuildLastProgress,
    this.zeroBuildLastChanged,
    this.zeroBuildDailyMatches,
    this.zeroBuildRankImagePath,
    this.zeroBuildRank,
    required this.zeroBuildActive,
    this.zeroBuildTracking,
    this.rocketRacingProgressText,
    this.rocketRacingProgress,
    this.rocketRacingLastProgress,
    this.rocketRacingLastChanged,
    this.rocketRacingDailyMatches,
    this.rocketRacingRankImagePath,
    this.rocketRacingRank,
    required this.rocketRacingActive,
    this.rocketRacingTracking,
  });

  @override
  RankCardState createState() => RankCardState();
}

class RankCardState extends State<RankCard>
    with SingleTickerProviderStateMixin {
  late bool _battleRoyaleTracking;
  late bool _zeroBuildTracking;
  late bool _rocketRacingTracking;

  @override
  void initState() {
    super.initState();
    _battleRoyaleTracking = widget.battleRoyaleTracking ?? false;
    _zeroBuildTracking = widget.zeroBuildTracking ?? false;
    _rocketRacingTracking = widget.rocketRacingTracking ?? false;
  }

  void _copyText(String textToCopy) {
    Clipboard.setData(ClipboardData(text: textToCopy));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Text copied to clipboard')),
    );
  }

  Future<void> _updatePlayerTracking(bool value, int key) async {
    await DataBase().updatePlayerTracking(
        value, key, widget.accountId!, widget.displayName);
    RankService().refreshMainPage();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: widget.color,
      elevation: 15,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: DefaultTabController(
        initialIndex: widget.initialIndex!,
        length: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                children: [
                  if (widget.accountAvatar != null)
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: NetworkImage(widget.accountAvatar!),
                    ),
                  const SizedBox(
                    width: 24,
                  ),
                  Expanded(
                    child: Text(
                      widget.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  if (widget.showMenu)
                    PopupMenuButton<String>(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      onSelected: (String value) {
                        if (value == "cpy_display_name") {
                          _copyText(widget.displayName);
                        } else if (value == "cpy_account_id") {
                          _copyText(widget.accountId!);
                        } else if (value == "open_user") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SearchScreen(
                                      accountId: widget.accountId,
                                      displayName: widget.displayName,
                                    )),
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          const PopupMenuItem<String>(
                            value: "open_user",
                            child: Row(
                              children: [
                                Padding(
                                    padding: EdgeInsets.only(right: 8.0),
                                    child: Icon(Icons.open_in_new)),
                                Text(
                                  'Open User',
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            value: "cpy_display_name",
                            child: Row(
                              children: [
                                Padding(
                                    padding: EdgeInsets.only(right: 8.0),
                                    child: Icon(Icons.copy)),
                                Text(
                                  'Copy Display Name',
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: "cpy_account_id",
                            child: Row(
                              children: [
                                Padding(
                                    padding: EdgeInsets.only(right: 8.0),
                                    child: Icon(Icons.copy)),
                                Text(
                                  'Copy Account Id',
                                ),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                ],
              ),
            ),
            const TabBar(
              tabs: [
                Tab(
                  child: Text(
                    "Battle Royale",
                    textAlign: TextAlign.center,
                  ),
                ),
                Tab(
                  child: Text(
                    "Zero Build",
                    textAlign: TextAlign.center,
                  ),
                ),
                Tab(
                  child: Text(
                    "Rocket Racing",
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              indicatorColor: Colors.deepPurple,
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildContent(
                    widget.battleRoyaleProgressText,
                    widget.battleRoyaleProgress,
                    widget.battleRoyaleLastProgress,
                    widget.battleRoyaleLastChanged,
                    widget.battleRoyaleDailyMatches,
                    widget.battleRoyaleRankImagePath,
                    widget.battleRoyaleRank,
                    widget.battleRoyaleActive,
                    _battleRoyaleTracking,
                    "Battle Royale",
                    (bool value) async {
                      setState(() {
                        _battleRoyaleTracking = value;
                      });
                      await _updatePlayerTracking(value, 0);
                    },
                  ),
                  _buildContent(
                    widget.zeroBuildProgressText,
                    widget.zeroBuildProgress,
                    widget.zeroBuildLastProgress,
                    widget.zeroBuildLastChanged,
                    widget.zeroBuildDailyMatches,
                    widget.zeroBuildRankImagePath,
                    widget.zeroBuildRank,
                    widget.zeroBuildActive,
                    _zeroBuildTracking,
                    "Zero Build",
                    (bool value) async {
                      setState(() {
                        _zeroBuildTracking = value;
                      });
                      await _updatePlayerTracking(value, 1);
                    },
                  ),
                  _buildContent(
                    widget.rocketRacingProgressText,
                    widget.rocketRacingProgress,
                    widget.rocketRacingLastProgress,
                    widget.rocketRacingLastChanged,
                    widget.rocketRacingDailyMatches,
                    widget.rocketRacingRankImagePath,
                    widget.rocketRacingRank,
                    widget.rocketRacingActive,
                    _rocketRacingTracking,
                    "Rocket Racing",
                    (bool value) async {
                      setState(() {
                        _rocketRacingTracking = value;
                      });
                      await _updatePlayerTracking(value, 2);
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

  Widget _buildContent(
      String? progressText,
      double? progress,
      String? lastProgress,
      String? lastChanged,
      int? dailyMatches,
      String? rankImagePath,
      String? rank,
      bool active,
      bool? tracking,
      String category,
      Future<void> Function(bool) onTrackingChanged) {
    if (!active) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Tracking for `$category` is not active!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 15),
          FilledButton.icon(
              onPressed: () {
                onTrackingChanged(true);
              },
              icon: const Icon(Icons.check),
              label: const Text("Activate"))
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (progress != null)
              CircularPercentIndicator(
                radius: 50,
                lineWidth: 6,
                percent: progress,
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: Colors.deepPurple,
                header: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    lastChanged ?? "",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
                footer: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Visibility(
                    visible: dailyMatches != null,
                    child: Text("Daily Matches: $dailyMatches"),
                  ),
                ),
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(progressText ?? ""),
                    if (lastProgress != null)
                      Text(
                        lastProgress,
                        style: const TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (rankImagePath != null)
                  Image.asset(
                    rankImagePath,
                    width: 75,
                    height: 75,
                  ),
                const SizedBox(
                  height: 15,
                ),
                Text(
                  rank ?? "No Rank",
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (widget.showSwitches) _buildSwitches(tracking!, onTrackingChanged)
      ],
    );
  }

  Widget _buildSwitches(bool tracking, Function trackingChanged) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Tracking:",
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(
            width: 16,
          ),
          Switch(
            value: tracking,
            onChanged: (bool value) {
              trackingChanged(value);
            },
          ),
        ],
      ),
    );
  }
}
