import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class RankCard extends StatefulWidget {
  final String displayName;

  final String? battleRoyaleProgressText;
  final double? battleRoyaleProgress;
  final String? battleRoyaleLastProgress;
  final String? battleRoyaleLastChanged;
  final int? battleRoyaleDailyMatches;
  final String? battleRoyaleRankImagePath;
  final String? battleRoyaleRank;
  final bool battleRoyaleActive;

  final String? zeroBuildProgressText;
  final double? zeroBuildProgress;
  final String? zeroBuildLastProgress;
  final String? zeroBuildLastChanged;
  final int? zeroBuildDailyMatches;
  final String? zeroBuildRankImagePath;
  final String? zeroBuildRank;
  final bool zeroBuildActive;

  final String? rocketRacingProgressText;
  final double? rocketRacingProgress;
  final String? rocketRacingLastProgress;
  final String? rocketRacingLastChanged;
  final int? rocketRacingDailyMatches;
  final String? rocketRacingRankImagePath;
  final String? rocketRacingRank;
  final bool rocketRacingActive;

  const RankCard(
      {super.key,
      required this.displayName,
      this.battleRoyaleProgressText,
      this.battleRoyaleProgress,
      this.battleRoyaleLastProgress,
      this.battleRoyaleLastChanged,
      this.battleRoyaleDailyMatches,
      this.battleRoyaleRankImagePath,
      this.battleRoyaleRank,
      required this.battleRoyaleActive,
      this.zeroBuildProgressText,
      this.zeroBuildProgress,
      this.zeroBuildLastProgress,
      this.zeroBuildLastChanged,
      this.zeroBuildDailyMatches,
      this.zeroBuildRankImagePath,
      this.zeroBuildRank,
      required this.zeroBuildActive,
      this.rocketRacingProgressText,
      this.rocketRacingProgress,
      this.rocketRacingLastProgress,
      this.rocketRacingLastChanged,
      this.rocketRacingDailyMatches,
      this.rocketRacingRankImagePath,
      this.rocketRacingRank,
      required this.rocketRacingActive});

  @override
  RankCardState createState() => RankCardState();
}

class RankCardState extends State<RankCard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shadowColor: Colors.deepPurple,
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: DefaultTabController(
        length: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Text(
                widget.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
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
                    "Battle Royale",
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
                    "Zero Build",
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
                    "Rocket Racing",
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
      String category) {
    if (!active) {
      return Center(
        child: Text(
          'Tracking for `$category` is not active!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        CircularPercentIndicator(
          radius: 50,
          lineWidth: 6,
          percent: progress ?? 0,
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
    );
  }
}
