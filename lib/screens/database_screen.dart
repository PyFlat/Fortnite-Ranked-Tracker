import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
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

  Future<Map<String, dynamic>> _fetchSchemaAndData() async {
    await Future.delayed(Duration(seconds: 1));

    Database db = await _database.openDatabase(widget.account["accountId"]);

    // Get the column names
    final columnsQuery =
        await db.rawQuery("PRAGMA table_info('chapter_5_season_3_br')");
    final columnNames =
        columnsQuery.map((column) => column['name'] as String).toList();

    // Get the data
    final data = await db.rawQuery("SELECT * FROM chapter_5_season_3_br");

    return {
      'columns': columnNames,
      'data': data,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Database of ${widget.account["displayName"]}"),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchSchemaAndData(),
        builder: (BuildContext context,
            AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!['data'].isEmpty) {
            return Center(child: Text('No data available'));
          } else {
            final columns = snapshot.data!['columns'] as List<String>;
            final data = snapshot.data!['data'] as List<Map<String, dynamic>>;

            return DataTable2(
              columnSpacing: 12,
              horizontalMargin: 12,
              minWidth: 600,
              columns: columns.map<DataColumn>((columnName) {
                return DataColumn(
                  label: Text(columnName),
                  numeric: columnName
                      .toLowerCase()
                      .contains('number'), // Adjust if needed
                );
              }).toList(),
              rows: data.map<DataRow>((row) {
                return DataRow(
                    cells: columns.map<DataCell>((columnName) {
                  return DataCell(Text(row[columnName]?.toString() ?? ''));
                }).toList());
              }).toList(),
            );
          }
        },
      ),
    );
  }
}
