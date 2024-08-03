import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:fortnite_ranked_tracker/core/utils.dart'; // Ensure this import is correct
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
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
  String? _currentSeason; // No default season, it's now nullable

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentSeason == null) {
      // Only open the bottom sheet if a season hasn't been selected
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openSeasonBottomSheet();
      });
    }
  }

  Future<List<String>> _fetchSeasons() async {
    List<String> trackedSeasons =
        await _database.getTrackedSeasons(widget.account["accountId"]);

    return trackedSeasons;
  }

  Future<Map<String, dynamic>> _fetchSchemaAndData() async {
    if (_currentSeason == null) {
      throw Exception("No season selected");
    }

    await Future.delayed(const Duration(milliseconds: 200));

    Database db = await _database.openDatabase(widget.account["accountId"]);

    final columnsQuery =
        await db.rawQuery("PRAGMA table_info('$_currentSeason')");
    final columnNames =
        columnsQuery.map((column) => column['name'] as String).toList();

    final data = await db.rawQuery("SELECT * FROM $_currentSeason");

    return {
      'columns': columnNames,
      'data': data,
    };
  }

  final List<String> columns = <String>[
    "ID",
    "Datetime",
    "Rank",
    "Progress",
    "Daily Match ID",
    "Total Progress"
  ];

  void _openSeasonBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<List<String>>(
          future: _fetchSeasons(),
          builder:
              (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No seasons available'));
            } else {
              final seasons = snapshot.data!;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Select Season",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: seasons.length,
                      itemBuilder: (context, index) {
                        String season = seasons[index];
                        Map<String, String> season_ =
                            splitAndPrettifySeasonString(season);

                        return ListTile(
                          title: Text(season_["season"]!),
                          subtitle: Text(season_["mode"]!),
                          onTap: () {
                            setState(() {
                              _currentSeason = season;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            }
          },
        );
      },
    );
  }

  void _refreshData() {
    setState(() {
      // Triggers a rebuild of the screen with updated data
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Database of ${widget.account["displayName"]}"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: "Refresh Data",
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final seasonInfo = _currentSeason != null
                          ? splitAndPrettifySeasonString(_currentSeason!)
                          : null;

                      final displayText = seasonInfo != null
                          ? "Season ${seasonInfo["season"]!}: ${seasonInfo["mode"]!}"
                          : "Select a Season";

                      return Text(
                        displayText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: _openSeasonBottomSheet,
                  child: Text("Change Season"),
                ),
                Spacer(),
              ],
            ),
          ),
          Expanded(
            child: _currentSeason == null
                ? Center(child: Text("Please select a season"))
                : FutureBuilder<Map<String, dynamic>>(
                    future: _fetchSchemaAndData(),
                    builder: (BuildContext context,
                        AsyncSnapshot<Map<String, dynamic>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: DataTable2(
                            empty: const Center(
                                child: Text(
                              "Data loading...",
                              style: TextStyle(fontSize: 24),
                            )),
                            columnSpacing: 12,
                            horizontalMargin: 12,
                            minWidth: 600,
                            columns: columns.map<DataColumn>((columnName) {
                              return DataColumn(
                                label: Center(
                                  child: Text(
                                    columnName,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                numeric: columnName
                                    .toLowerCase()
                                    .contains('number'), // Adjust if needed
                              );
                            }).toList(),
                            rows: [],
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData ||
                          snapshot.data!['data'].isEmpty) {
                        return const Center(child: Text('No data available'));
                      } else {
                        final dbColumns =
                            snapshot.data!['columns'] as List<String>;
                        final data = snapshot.data!['data']
                            as List<Map<String, dynamic>>;

                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: DataTable2(
                            columnSpacing: 12,
                            horizontalMargin: 12,
                            minWidth: 600,
                            columns: columns.map<DataColumn>((columnName) {
                              return DataColumn(
                                label: Center(
                                  child: Text(
                                    columnName,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                numeric: columnName
                                    .toLowerCase()
                                    .contains('number'), // Adjust if needed
                              );
                            }).toList(),
                            rows: data.map<DataRow>((row) {
                              return DataRow(
                                  cells: dbColumns.map<DataCell>((columnName) {
                                return DataCell(Center(
                                    child: Text(
                                  row[columnName
                                              .toLowerCase()
                                              .replaceAll(" ", "_")]
                                          ?.toString() ??
                                      '',
                                  textAlign: TextAlign.center,
                                )));
                              }).toList());
                            }).toList(),
                          ),
                        );
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
