import '../core/rank_service.dart';
import '../core/utils.dart';

import '../components/dashboard_card.dart';
import '../core/database.dart';
import 'package:flutter/material.dart';

import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final DataBase _database = DataBase();
  final RankService _rankService = RankService();

  @override
  void initState() {
    super.initState();
    _rankService.rankUpdates.listen((_) {
      if (mounted) {
        setState(() {
          _getData();
        });
      }
    });
  }

  String calculatePercentageDifference(int currentProgress,
      int previousProgress, String currentRank, String previousRank) {
    String percentageDifference = "-";
    if (currentRank == "Unreal") {
      if (previousRank != "Champion") {
        percentageDifference = (previousProgress - currentProgress).toString();
      } else {
        percentageDifference = "${1700 - previousProgress}%";
      }
    } else {
      percentageDifference = "${currentProgress - previousProgress}%";
    }

    return percentageDifference;
  }

  Future<List<Map<String, dynamic>>> _getData() async {
    List<Map<String, dynamic>> data = await _database.getAccountDataActive();
    final accountTypes = {
      "Battle Royale": "br",
      "Zero Build": "zb",
      "Rocket Racing": "rr"
    };

    for (Map<String, dynamic> account in data) {
      for (var entry in accountTypes.entries) {
        String accountType = entry.key;
        String typeCode = entry.value;

        if (account.containsKey(accountType)) {
          try {
            List result = await _rankService.getRankedDataByAccountId(
                account["AccountId"], typeCode);

            if (result.isEmpty) {
              continue;
            }

            var rankData = result[0];

            int dataProgress = rankData["progress"];
            String lastProgress = "-";

            if (result.length > 1) {
              lastProgress = calculatePercentageDifference(
                  rankData["total_progress"],
                  result[1]["total_progress"],
                  rankData["rank"],
                  result[1]["rank"]);
            }

            double progress = rankData["rank"] != "Unreal"
                ? dataProgress / 100
                : convertProgressForUnreal(dataProgress.toDouble());

            String progressText = rankData["rank"] == "Unreal"
                ? '#$dataProgress'
                : "$dataProgress%";

            int dailyMatches;
            if (DateTime.now()
                    .difference(DateTime.parse(rankData["datetime"]))
                    .inDays ==
                0) {
              dailyMatches = rankData["daily_match_id"];
            } else {
              dailyMatches = 0;
            }

            account[accountType] = {
              "DailyMatches": dailyMatches,
              "LastProgress": lastProgress,
              "LastChanged": formatDateTime(rankData["datetime"]),
              "Rank": rankData["rank"],
              "RankProgression": progress,
              "RankProgressionText": progressText
            };
          } catch (e) {
            print(
                "Error updating $accountType for account ${account['AccountId']}: $e");
          }
        }
      }
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SearchScreen()),
          );
        },
        label: const Text("Search"),
        icon: const Icon(Icons.search),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<List<dynamic>>(
          future: _getData(),
          builder: (context, snapshot) {
            var dat = snapshot.data ?? [];
            return SingleChildScrollView(
              child: Center(
                child: Wrap(
                  spacing: 10.0, // Spacing between items
                  runSpacing: 10.0, // Spacing between lines
                  children: dat.map((item) {
                    return SizedBox(
                      width: 350.0, // Fixed width of each card
                      height: 350.0, // Fixed height of each card
                      child: Padding(
                        padding:
                            EdgeInsets.all(8.0), // Padding around each card
                        child: DashboardCard(item: item),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
