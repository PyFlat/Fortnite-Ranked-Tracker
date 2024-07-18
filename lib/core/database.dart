import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DataBase {
  late Database _db;
  late Directory _directory;
  List<String> keys = ["battleRoyale", "zeroBuild", "rocketRacing"];

  // Private constructor
  DataBase._();

  // Singleton instance
  static final DataBase _instance = DataBase._();

  // Factory method to access the singleton instance
  factory DataBase() => _instance;

  Future<void> init() async {
    await _initDatabase();
  }

  Future<void> _initDatabase() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
    }
    var databaseFactory = databaseFactoryFfi;
    _directory = await getApplicationSupportDirectory();
    String directoryPath = join(_directory.path, 'databases');
    String dbPath = join(directoryPath, 'system.db');

    await Directory(directoryPath).create(recursive: true);

    _db = await databaseFactory.openDatabase(dbPath);
    await _createTables(_db);
  }

  Future<void> _createTables(Database db) async {
    List<String> types = ["battleRoyale", "zeroBuild", "rocketRacing"];
    Batch batch = db.batch();

    for (String type in types) {
      batch.execute('''
        CREATE TABLE IF NOT EXISTS $type (
          accountId TEXT PRIMARY KEY,
          accountType TEXT,
          displayName TEXT,
          active INTEGER
        )
      ''');
    }

    await batch.commit();
  }

  Future<void> updatePlayerTracking(
      bool tracking, int key, List<dynamic> data) async {
    await init(); // Ensure database is initialized
    String tableName = keys[key];
    Map<String, dynamic> params = {
      'accountId': data[0],
      'accountType': data[1],
      'displayName': data[2],
      'active': tracking ? 1 : 0,
    };

    List<Map<String, dynamic>> existingRecords = await _db.query(
      tableName,
      columns: ['accountId'],
      where: 'accountId = ?',
      whereArgs: [params['accountId']],
    );

    if (existingRecords.isNotEmpty) {
      await _db.update(
        tableName,
        params,
        where: 'accountId = ?',
        whereArgs: [params['accountId']],
      );
    } else {
      await _db.insert(tableName, params);
    }
  }

  Future<bool> getPlayerTracking(int key, String accountId) async {
    await init(); // Ensure database is initialized
    String tableName = keys[key];

    List<Map<String, dynamic>> result = await _db.query(
      tableName,
      columns: ['accountId', 'active'],
      where: 'accountId = ?',
      whereArgs: [accountId],
    );

    return result.isNotEmpty ? result[0]['active'] == 1 : false;
  }

  Future<void> removePlayer(String accountId) async {
    await init(); // Ensure database is initialized
    for (int i = 0; i < 3; i++) {
      String tableName = keys[i];

      await _db.delete(
        tableName,
        where: 'accountId = ?',
        whereArgs: [accountId],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getAccountDataActive() async {
    List<Map<String, dynamic>> brAccounts = await getAccountDataByType(
        0, "accountType, accountId, displayName", true);
    List<Map<String, dynamic>> zbAccounts = await getAccountDataByType(
        1, "accountType, accountId, displayName", true);
    List<Map<String, dynamic>> rrAccounts = await getAccountDataByType(
        2, "accountType, accountId, displayName", true);

    // Collect all unique account IDs
    Set<String> allAccountIds = {
      ...brAccounts.map((account) => account["accountId"]),
      ...zbAccounts.map((account) => account["accountId"]),
      ...rrAccounts.map((account) => account["accountId"]),
    };

    List<Map<String, dynamic>> result = [];

    for (var accountId in allAccountIds) {
      var accountData = <String, dynamic>{
        "AccountId": accountId,
        "DisplayName": "",
        "AccountType": "",
        "Battle Royale": {},
        "Zero Build": {},
        "Rocket Racing": {},
      };

      void updateAccountData(Map<String, dynamic>? account) {
        if (account != null && account.isNotEmpty) {
          accountData["DisplayName"] = account["displayName"];
          accountData["AccountType"] = account["accountType"];
        }
      }

      var brAccount = brAccounts.firstWhere(
        (account) => account["accountId"] == accountId,
        orElse: () => <String, dynamic>{},
      );
      updateAccountData(brAccount);

      var zbAccount = zbAccounts.firstWhere(
        (account) => account["accountId"] == accountId,
        orElse: () => <String, dynamic>{},
      );
      if (zbAccount.isEmpty) {
        accountData.remove("Zero Build");
      } else {
        updateAccountData(zbAccount);
      }

      var rrAccount = rrAccounts.firstWhere(
        (account) => account["accountId"] == accountId,
        orElse: () => <String, dynamic>{},
      );
      if (rrAccount.isEmpty) {
        accountData.remove("Rocket Racing");
      } else {
        updateAccountData(rrAccount);
      }

      result.add(accountData);
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getAccountDataByType(
      int key, String columns, bool active) async {
    await init(); // Ensure database is initialized
    String tableName = keys[key];

    int activeValue = active ? 1 : 0;

    List<Map<String, dynamic>> result = await _db.query(
      tableName,
      columns: [columns],
      where: 'active = ?',
      whereArgs: [activeValue],
    );

    return result;
  }

  Future<List<List<Map<String, dynamic>>>> getAllAccountData() async {
    await init(); // Ensure database is initialized
    List<List<Map<String, dynamic>>> result = [];

    for (int i = 0; i < 3; i++) {
      String tableName = keys[i];

      List<Map<String, dynamic>> items = await _db.query(tableName,
          columns: ['accountType', 'displayName', 'accountId']);

      result.add(items);
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> getFilteredAccountData() async {
    await init(); // Ensure database is initialized
    List<List<Map<String, dynamic>>> rawAccountData = await getAllAccountData();

    List<String> existingAccounts =
        await Directory(join(_directory.path, 'databases'))
            .list()
            .map((FileSystemEntity entity) => entity.path)
            .toList();

    List<Map<String, dynamic>> filteredData = [];

    for (List<Map<String, dynamic>> data in rawAccountData) {
      for (Map<String, dynamic> currentData in data) {
        String accountId = currentData['accountId'];
        if (!existingAccounts.contains('$accountId.db')) {
          continue;
        }
        if (!filteredData.any((item) => item['accountId'] == accountId)) {
          filteredData.add(currentData);
        }
      }
    }

    return filteredData;
  }

  Future<void> updatePlayerName(
      int key, String accountId, String displayName) async {
    await init(); // Ensure database is initialized
    String tableName = keys[key];

    await _db.update(
      tableName,
      {'displayName': displayName},
      where: 'accountId = ?',
      whereArgs: [accountId],
    );
  }
}
