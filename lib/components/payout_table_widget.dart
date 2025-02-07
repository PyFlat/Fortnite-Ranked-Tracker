import 'package:flutter/material.dart';
import 'package:fortnite_ranked_tracker/core/rank_service.dart';

class PayoutTableWidget extends StatefulWidget {
  final String eventId;
  final String windowId;

  final List<Map<String, dynamic>> allLeaderboardData;
  const PayoutTableWidget(
      {super.key,
      required this.eventId,
      required this.windowId,
      required this.allLeaderboardData});

  @override
  PayoutTableWidgetState createState() => PayoutTableWidgetState();
}

class PayoutTableWidgetState extends State<PayoutTableWidget> {
  List<Map<String, dynamic>> _payoutTable = [];
  Future<void>? _future;

  @override
  void initState() {
    _future = getPayoutTable();
    super.initState();
  }

  Future<void> getPayoutTable() async {
    _payoutTable = await RankService()
        .getEventPayoutTable(widget.eventId, widget.windowId);

    await updatePayoutTable();
  }

  Future<void> updatePayoutTable() async {
    for (var type in _payoutTable) {
      String scoringType = type["scoringType"];
      for (var rank in type["ranks"]) {
        if (scoringType == "rank") {
          final element = widget.allLeaderboardData.firstWhere(
            (element) => element["rank"] == int.parse(rank["threshold"]),
            orElse: () => {},
          );

          if (element != {}) {
            rank["points"] = element["points"];
          }
        }
        for (var payout in rank["payouts"]) {
          String rewardType = payout["rewardType"];
          if (rewardType == "game") {
            String id = (payout["value"] as String).split(":")[1];
            final cosmetic = await RankService().searchCosmetic(id);
            payout["name"] = cosmetic["name"];
            payout["url"] = cosmetic["images"]["smallIcon"];
          } else if (rewardType == "token") {
            final eventInfo =
                await RankService().getEventIdInfo(payout["value"]);
            payout["name"] = eventInfo["longTitle"];
            payout["sessionName"] = eventInfo["windowName"];
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (_payoutTable.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "This event doesn't have any prizes.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            children: _payoutTable
                .map((table) => _buildPayoutTableItem(table))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildPayoutTableItem(Map<String, dynamic> table) {
    String title = table["scoringType"];
    if (title == "value") {
      title = "Point Rewards";
    } else if (title == "rank") {
      title = "Placement Rewards";
    } else if (title == "percentile") {
      title = "Percentile Rewards";
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
          SizedBox(height: 12),
          ...(table["ranks"] as List).map<Widget>((rank) {
            return _buildRankItem(rank, table["scoringType"]);
          }),
        ],
      ),
    );
  }

  Widget _buildRankItem(Map<String, dynamic> rank, String scoringType) {
    String threshold = rank["threshold"];
    int? points = rank["points"];
    List payouts = rank["payouts"];

    String text = "";
    String text2 = "";

    if (scoringType == "value") {
      text = "Earned $threshold Points";
    } else if (scoringType == "rank") {
      text = "Top #$threshold";
      text2 = "${points ?? "???"} Points";
    } else if (scoringType == "percentile") {
      text = "Top ${threshold * 100}%";
    }

    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                text,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                text2,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              )
            ],
          ),
          SizedBox(height: 8),
          ...payouts.map<Widget>((payout) {
            return _buildPayoutDetails(payout);
          }),
        ],
      ),
    );
  }

  Widget _buildPayoutDetails(Map<String, dynamic> payout) {
    String rewardType = payout["rewardType"];
    int quantity = payout["quantity"];
    String? name = payout["name"];
    String? sessionName = payout["sessionName"];

    String? iconUrl = payout["url"];

    String text1 = "";
    String text2 = "";
    String text3 = "";

    if (rewardType == "ecomm") {
      text1 = "Earnings";
      text2 = "\$$quantity";
    } else if (rewardType == "token") {
      text1 = "Qualify";
      text2 = name ?? "";
      text3 = sessionName ?? "";
    } else if (rewardType == "game") {
      text1 = "Earn Cosmetic";
      text2 = name ?? "";
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withValues(alpha: .6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                spacing: 6,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text2,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (text3.isNotEmpty)
                    Text(
                      text3,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  if (iconUrl != null)
                    Image.network(
                      iconUrl,
                      width: 60,
                      height: 60,
                    )
                ],
              ),
            ),
            SizedBox(width: 8),
            Text(
              text1,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
