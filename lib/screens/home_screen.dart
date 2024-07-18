import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

  Future<List<Map<String, dynamic>>> _getData() async {
    List<Map<String, dynamic>> data = await _database.getAccountDataActive();
    // for (Map dat in data) {
    //   var databaseFactory = databaseFactoryFfi;
    //   Directory directory = await getApplicationSupportDirectory();
    //   String directoryPath =
    //       "${directory.path}/databases/${dat["AccountId"]}.db";
    //   Database _db = await databaseFactory.openDatabase(directoryPath);
    //   _db.query(table)
    // }

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
