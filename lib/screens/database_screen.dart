import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart'; // Correct import for sqflite
import '../core/database.dart';
import 'package:talker_flutter/talker_flutter.dart';

class DatabaseScreen extends StatefulWidget {
  final Talker talker;
  final Map<String, dynamic> account;

  DatabaseScreen({super.key, required this.talker, required this.account});

  @override
  State<DatabaseScreen> createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
  final DataBase _database = DataBase();

  Future<List<Map<String, dynamic>>> _fetchData() async {
    Database db = await _database.openDatabase(widget.account["accountId"]);
    final result = await db.rawQuery("SELECT * FROM chapter_5_season_3_br");
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Database of ${widget.account["displayName"]}"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchData(),
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data available'));
          } else {
            List<Map<String, dynamic>> data = snapshot.data!;
            return SingleChildScrollView(
              child: DataTable(
                columnSpacing: 12,
                horizontalMargin: 12,
                columns: [
                  const DataColumn(label: Text('Match'), numeric: true),
                  const DataColumn(
                    label: Text('Datetime'),
                  ),
                  const DataColumn(
                    label: Text('Rank'),
                  ),
                  const DataColumn(
                    label: Text('Rank Progression'),
                    numeric: true,
                  ),
                  const DataColumn(
                    label: Text('Daily Match'),
                    numeric: true,
                  ),
                  const DataColumn(
                    label: Text('Total Progression'),
                    numeric: true,
                  ),
                ],
                rows: data.map<DataRow>((row) {
                  return DataRow(cells: [
                    DataCell(Text(row['id'].toString())),
                    DataCell(Text(row['datetime'].toString())),
                    DataCell(Text(row['rank'].toString())),
                    DataCell(Text(row['progress'].toString())),
                    DataCell(Text(row['daily_match_id'].toString())),
                    DataCell(Text(row['total_progress'].toString())),
                  ]);
                }).toList(),
              ),
            );
          }
        },
      ),
    );
  }
}
