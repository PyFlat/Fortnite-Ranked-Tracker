import 'package:auth_flow_example/core/rank_service.dart';
import 'package:auth_flow_example/core/utils.dart';

import '../components/dashbord_card.dart';
import '../core/database.dart';
import 'package:flutter/material.dart';
// import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final DataBase _database = DataBase();
  final RankService _rankService = RankService();

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

            int dataProgres = rankData["progress"];

            double progress = rankData["rank"] != "Unreal"
                ? dataProgres / 100
                : convertProgressForUnreal(dataProgres.toDouble());

            String progressText = rankData["rank"] == "Unreal"
                ? '#$dataProgres'
                : "$dataProgres%";

            account[accountType] = {
              "DailyMatches": rankData["daily_match_id"],
              "LastProgress": progressText,
              "LastChanged": "10.06.2024 19:48",
              "Rank": rankData["rank"],
              "RankProgression": progress,
              "RankProgressionText": progressText
            };
          } catch (e) {
            // Handle or log errors as appropriate
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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<List<dynamic>>(
          future: _getData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No data available'));
            } else {
              var dat = snapshot.data!;
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
                          child: MyCard(item: item),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
