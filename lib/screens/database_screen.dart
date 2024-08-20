import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:fortnite_ranked_tracker/components/individual_page_header.dart';
import '../components/season_selector.dart';
import '../core/season_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../core/database.dart';

class DatabaseScreen extends StatefulWidget {
  final Map<String, dynamic> account;

  const DatabaseScreen({super.key, required this.account});

  @override
  State<DatabaseScreen> createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
  final SeasonService _seasonService = SeasonService();
  final DataBase _database = DataBase();
  int _sortedColumn = 0;
  bool _isAscending = false;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seasonService.getCurrentSeason() == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openSeasonBottomSheet();
      });
    }
  }

  void _openSeasonBottomSheet() {
    SeasonSelector(
      seasonService: _seasonService,
      accountId: widget.account["accountId"],
      onSeasonSelected: _refreshData,
    ).openSeasonBottomSheet(context);
  }

  Future<Map<String, dynamic>> _fetchSchemaAndData() async {
    final currentSeason = _seasonService.getCurrentSeason();
    if (currentSeason == null) {
      throw Exception("No season selected");
    }

    await Future.delayed(const Duration(milliseconds: 200));

    Database db = await _database.openDatabase(widget.account["accountId"]);

    final columnsQuery =
        await db.rawQuery("PRAGMA table_info('$currentSeason')");
    final columnNames =
        columnsQuery.map((column) => column['name'] as String).toList();

    final sortClause =
        "ORDER BY ${columns2[_sortedColumn]} ${_isAscending ? 'ASC' : 'DESC'}";

    final data = await db.rawQuery("SELECT * FROM $currentSeason $sortClause");

    return {
      'columns': columnNames,
      'data': data,
    };
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
          IndividualPageHeader(
              seasonService: _seasonService,
              accountId: widget.account["accountId"],
              onSeasonSelected: _refreshData),
          Expanded(
            child: _seasonService.getCurrentSeason() == null
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
                            rows: const [],
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
