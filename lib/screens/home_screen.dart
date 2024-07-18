import 'package:auth_flow_example/components/dashbord_card.dart';
import 'package:flutter/material.dart';
// import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final List<Map<dynamic, dynamic>> data = [
    {
      "AccountId": "1",
      "DisplayName": "Anonym 2546",
      "Battle Royale": {
        "DailyMatches": "0",
        "LastProgress": "119",
        "LastChanged": "17.07.2024 21:45",
        "Rank": "Unreal",
        "RankProgression": "#21677"
      },
      "Zero Build": {
        "DailyMatches": "0",
        "LastProgress": "53%",
        "LastChanged": "10.06.2024 19:48",
        "Rank": "Gold II",
        "RankProgression": "42%"
      },
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Center(
            child: Wrap(
              spacing: 10.0, // Spacing between items
              runSpacing: 10.0, // Spacing between lines
              children: data.map((item) {
                return SizedBox(
                  width: 350.0, // Fixed width of each card
                  height: 350.0, // Fixed height of each card
                  child: Padding(
                    padding: EdgeInsets.all(8.0), // Padding around each card
                    child: MyCard(item: item),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
