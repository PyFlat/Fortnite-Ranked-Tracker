import 'package:flutter/material.dart';
import 'package:fortnite_ranked_tracker/components/tournament_details_sheet.dart';

class ScoringRulesWidget extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> scoringRules;
  final String id;
  final String? cumulativeId;

  const ScoringRulesWidget(
      {super.key,
      required this.scoringRules,
      required this.id,
      required this.cumulativeId});

  @override
  ScoringRulesWidgetState createState() => ScoringRulesWidgetState();
}

class ScoringRulesWidgetState extends State<ScoringRulesWidget> {
  bool countTogether = false;

  @override
  Widget build(BuildContext context) {
    String id;
    if (widget.scoringRules.containsKey(widget.id)) {
      id = widget.id;
    } else {
      id = widget.cumulativeId!;
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        children: widget.scoringRules[id]!
            .map((rule) => _buildRuleItem(rule))
            .toList(),
      ),
    );
  }

  Widget _buildRuleItem(Map<String, dynamic> rule) {
    String title;

    if (rule['trackedStat'] == 'PLACEMENT_STAT_INDEX') {
      title = "Placement Rewards";
    } else {
      title = "Elimination Rewards";
    }

    return Container(
      width: 275,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ],
              ),
              if (rule['trackedStat'] == 'PLACEMENT_STAT_INDEX')
                CustomSwitch(
                  value: countTogether,
                  onChanged: (value) {
                    setState(() {
                      countTogether = value;
                    });
                  },
                )
            ],
          ),
          SizedBox(height: 12),
          Column(
            children: _buildRewardContainers(rule),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRewardContainers(Map<String, dynamic> rule) {
    List rewardTiers = rule['rewardTiers'];
    rewardTiers.sort((a, b) => a['keyValue'].compareTo(b['keyValue']));

    return rewardTiers.map((tier) {
      int cumulativePoints = countTogether
          ? _getCumulativePoints(tier, rewardTiers)
          : tier['pointsEarned'];

      String? prefixText;
      String? postfixText;

      if (rule['trackedStat'] == 'PLACEMENT_STAT_INDEX') {
        prefixText = "Top";
      } else if (rule['trackedStat'] == 'TEAM_ELIMS_STAT_INDEX') {
        prefixText = "Every";
        postfixText = "Elimination";
      }

      return Container(
        margin: EdgeInsets.only(top: 8),
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withValues(alpha: .5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "$prefixText ${tier['keyValue']}${postfixText != null ? " $postfixText" : ""}",
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            SizedBox(width: 12),
            Text(
              "$cumulativePoints points",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
        ),
      );
    }).toList();
  }

  int _getCumulativePoints(Map<String, dynamic> currentTier, List rewardTiers) {
    int cumulativePoints = 0;
    int currentIndex = rewardTiers.indexOf(currentTier);

    for (int i = currentIndex; i < rewardTiers.length; i++) {
      cumulativePoints += rewardTiers[i]['pointsEarned'] as int;
    }

    return cumulativePoints;
  }
}
