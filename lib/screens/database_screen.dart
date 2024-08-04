import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import '../core/utils.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../core/database.dart';

class DatabaseScreen extends StatefulWidget {
  final Map<String, dynamic> account;

  DatabaseScreen({super.key, required this.account});

  @override
  State<DatabaseScreen> createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
  final DataBase _database = DataBase();
  String? _currentSeason;
  int _sortedColumn = 0;
  bool _isAscending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentSeason == null) {
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

    final sortClause =
        "ORDER BY ${columns2[_sortedColumn]} ${_isAscending ? 'ASC' : 'DESC'}";

    final data = await db.rawQuery("SELECT * FROM $_currentSeason $sortClause");

    return {
      'columns': columnNames,
      'data': data,
    };
  }

  final List<String> columns = <String>[
    "Total Match Id",
    "Datetime",
    "Rank",
    "Rank Progression",
    "Daily Match Id",
    "Total Progress"
  ];

  final List<String> columns2 = <String>[
    "id",
    "datetime",
    "rank",
    "progress",
    "daily_match_id",
    "total_progress"
  ];

  final List<int> sortableColumns = <int>[0, 3, 4, 5];

  void _openSeasonBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<List<String>>(
          future: _fetchSeasons(),
          builder:
              (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No seasons available'));
            } else {
              final seasons = snapshot.data!;
              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
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
                              _sortedColumn = 0;
                              _isAscending = false;
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
    setState(() {});
  }

  List<DataRow> _createRows(
      List<Map<String, dynamic>> data, List<String> columns) {
    return data.map<DataRow>((row) {
      return DataRow(
        cells: columns.map<DataCell>((columnName) {
          return DataCell(Center(
            child: Text(
              row[columnName]?.toString() ?? '',
              textAlign: TextAlign.center,
            ),
          ));
        }).toList(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Database of ${widget.account["displayName"]}"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    final seasonInfo = _currentSeason != null
                        ? splitAndPrettifySeasonString(_currentSeason!)
                        : null;

                    final displayText = seasonInfo != null
                        ? "${seasonInfo["season"]!} - ${seasonInfo["mode"]!}"
                        : "Select a Season";

                    return Text(
                      displayText,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    );
                  },
                ),
                SizedBox(
                  height: 12,
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _openSeasonBottomSheet,
                      child: const Text("Change Season"),
                    ),
                    SizedBox(
                      width: 24,
                    ),
                    FilledButton.icon(
                      icon: Icon(Icons.refresh),
                      onPressed: _refreshData,
                      label: const Text("Refresh"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _currentSeason == null
                ? const Center(child: Text("Please select a season"))
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
                            sortColumnIndex: _sortedColumn,
                            sortAscending: _isAscending,
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
                                onSort: (columnIndex, ascending) {
                                  if (sortableColumns.contains(columnIndex)) {
                                    setState(() {
                                      _sortedColumn = columnIndex;
                                      _isAscending = ascending;
                                    });
                                  }
                                },
                              );
                            }).toList(),
                            rows: _createRows(data, dbColumns),
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
