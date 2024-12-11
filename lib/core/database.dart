import 'dart:io';
import 'package:fortnite_ranked_tracker/core/rank_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DataBase {
  late Database _db;
  late Directory _directory;
  bool systemDBInitialized = false;
  List<String> keys = [
    "battleRoyale",
    "zeroBuild",
    "rocketRacing",
    "reload",
    "reloadZeroBuild",
    "ballistics"
  ];

  DataBase._();

  static final DataBase _instance = DataBase._();

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
    await _initSystemDB(_db);
  }

  Future<Database> openDatabase(String accountId) async {
    var databaseFactory = databaseFactoryFfi;
    String dbPath = join(_directory.path, "databases/$accountId.db");
    return await databaseFactory.openDatabase(dbPath);
  }

  Future<void> _initSystemDB(Database db) async {
    if (systemDBInitialized) {
      return;
    }
    systemDBInitialized = true;
    Batch batch = db.batch();

    batch.execute('''
        CREATE TABLE IF NOT EXISTS profile0 (
          accountId TEXT PRIMARY KEY,
          displayName TEXT,
          nickName TEXT,
          battleRoyale INTEGER DEFAULT 0,
          zeroBuild INTEGER DEFAULT 0,
          rocketRacing INTEGER DEFAULT 0,
          reload INTEGER DEFAULT 0,
          reloadZeroBuild INTEGER DEFAULT 0,
          ballistics INTEGER DEFAULT 0,
          position INTEGER,
          visible INTEGER DEFAULT 1
        )
      ''');

    await batch.commit();

    _addColumnIfNotExists(db, "nickName", "TEXT");

    _addColumnIfNotExists(db, "reload", "INTEGER", defaultValue: 0);

    _addColumnIfNotExists(db, "reloadZeroBuild", "INTEGER", defaultValue: 0);

    _addColumnIfNotExists(db, "ballistics", "INTEGER", defaultValue: 0);
  }

  Future<void> _addColumnIfNotExists(
      Database db, String columnName, String columnType,
      {String tableName = "profile0", dynamic defaultValue}) async {
    List<Map<String, dynamic>> columns =
        await db.rawQuery('PRAGMA table_info($tableName)');

    List<String> existingColumns =
        columns.map((column) => column['name'] as String).toList();

    if (!existingColumns.contains(columnName)) {
      String defaultClause =
          defaultValue != null ? ' DEFAULT $defaultValue' : '';
      await db.execute(
          'ALTER TABLE $tableName ADD COLUMN $columnName $columnType$defaultClause');
    }
  }

  Future<void> updatePlayerTracking(
      bool tracking, int key, String accountId, String displayName,
      {String tableName = "profile0"}) async {
    await init();

    Map<String, dynamic> params = {
      'accountId': accountId,
      'displayName': displayName,
      keys[key]: tracking ? 1 : 0,
    };

    List<Map<String, dynamic>> existingRecords = await _db.query(
      tableName,
      columns: [
        'accountId',
        'battleRoyale',
        'zeroBuild',
        'rocketRacing',
        'reload',
        'reloadZeroBuild',
        'ballistics'
      ],
      where: 'accountId = ?',
      whereArgs: [params['accountId']],
    );

    if (existingRecords.isNotEmpty) {
      int activeSum = 0;
      for (String keyType in keys) {
        if (keyType == keys[key]) {
          activeSum += tracking ? 1 : 0;
          continue;
        }
        activeSum += existingRecords.first[keyType] as int;
      }
      params.addAll({"visible": activeSum == 0 ? 0 : 1});

      await _db.update(
        tableName,
        params,
        where: 'accountId = ?',
        whereArgs: [params['accountId']],
      );
    } else {
      List maxPosQuery =
          await _db.rawQuery("SELECT MAX(position) as pos FROM $tableName");
      int? maxPos = maxPosQuery.first['pos'];

      int pos = 0;
      if (maxPos != null) {
        pos = maxPos += 1;
      }
      params.addEntries({"position": pos}.entries);
      await _db.insert(tableName, params);
    }
  }

  Future<List<bool>> getPlayerTracking(String accountId,
      {String tableName = "profile0"}) async {
    await init();

    final List<Map<String, dynamic>> queryResult = await _db.query(
      tableName,
      columns: [
        'battleRoyale',
        'zeroBuild',
        'rocketRacing',
        'reload',
        'reloadZeroBuild',
        'ballistics'
      ],
      where: 'accountId = ?',
      whereArgs: [accountId],
    );

    if (queryResult.isEmpty) {
      return [false, false, false, false, false, false];
    }

    final Map<String, dynamic> playerData = queryResult.first;
    return [
      playerData['battleRoyale'] == 1,
      playerData['zeroBuild'] == 1,
      playerData['rocketRacing'] == 1,
      playerData['reload'] == 1,
      playerData['reloadZeroBuild'] == 1,
      playerData['ballistics'] == 1
    ];
  }

  Future<void> swapCardPositions(int position1, int position2,
      {String tableName = "profile0"}) async {
    await init();

    await _db.rawUpdate(
        "UPDATE $tableName SET position = CASE WHEN position = $position1 THEN $position2 WHEN position = $position2 THEN $position1 END WHERE position IN ($position1, $position2);");
  }

  Future<void> setAccountVisibility(String accountId, bool visible,
      {String tableName = "profile0"}) async {
    await init();
    int value = visible ? 1 : 0;
    await _db.rawUpdate(
        "UPDATE $tableName SET visible = $value WHERE accountId = '$accountId'");
  }

  Future<void> updateDataEdited(List<Map<String, dynamic>> data,
      {String tableName = "profile0"}) async {
    await init();
    for (Map item in data) {
      await _db.update(
        tableName,
        {
          'visible': item['Visible'],
          'position': item['Position'],
        },
        where: 'accountID = ?',
        whereArgs: [item['AccountId']],
      );
    }
  }

  Future<void> removePlayer(String accountId,
      {String tableName = "profile0"}) async {
    await init();

    await _db.delete(
      tableName,
      where: 'accountId = ?',
      whereArgs: [accountId],
    );
  }

  Future<List<Map<String, dynamic>>> getAccountDataActive(
      {String tableName = "profile0"}) async {
    await init();
    List accounts = await _db.query(tableName, columns: ["*"]);

    List<Map<String, dynamic>> result = [];

    for (var account in accounts) {
      var accountData = <String, dynamic>{
        "AccountId": account["accountId"],
        "DisplayName": account["displayName"],
        "NickName": account["nickName"],
        "Position": account["position"],
        "Visible": account["visible"]
      };

      if (account["battleRoyale"] == 1) {
        accountData["Battle Royale"] = {};
      }
      if (account["zeroBuild"] == 1) {
        accountData["Zero Build"] = {};
      }
      if (account["rocketRacing"] == 1) {
        accountData["Rocket Racing"] = {};
      }
      if (account["reload"] == 1) {
        accountData["Reload"] = {};
      }
      if (account["reloadZeroBuild"] == 1) {
        accountData["Reload Zero Build"] = {};
      }
      if (account["ballistics"] == 1) {
        accountData["Ballistics"] = {};
      }

      result.add(accountData);
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> getInactiveAccounts(
      {String tableName = "profile0"}) async {
    await init();

    List<Map<String, dynamic>> result = [];
    List accounts = await _db.query(tableName, columns: ["*"]);

    for (var account in accounts) {
      var accountData = <String, dynamic>{
        "AccountId": account["accountId"],
        "DisplayName": account["displayName"],
      };
      if (account["rocketRacing"] +
              account["battleRoyale"] +
              account["zeroBuild"] +
              account["reload"] +
              account["reloadZeroBuild"] +
              account["ballistics"] ==
          0) {
        result.add(accountData);
      }
    }
    return result;
  }

  Future<void> removeAccounts(List<String> accountIds,
      {String tableName = "profile0"}) async {
    await init();

    _db.delete(tableName, where: "accountId = ?", whereArgs: accountIds);
    for (String accountId in accountIds) {
      Database db = await openDatabase(accountId);
      await db.close();
      String path = join(_directory.path, "databases", "$accountId.db");
      await File(path).delete();
    }
    fixCardPositions();
    RankService().emitDataRefresh();
  }

  Future<void> fixCardPositions({String tableName = "profile0"}) async {
    await init();

    List<Map<String, dynamic>> accounts =
        await _db.query(tableName, columns: ["*"]);

    List<Map<String, dynamic>> mutableAccounts =
        accounts.map((map) => Map<String, dynamic>.from(map)).toList();

    mutableAccounts.sort((a, b) => a['position']!.compareTo(b['position']!));

    int currentPosition = 0;

    for (var map in mutableAccounts) {
      map['position'] = currentPosition;
      currentPosition++;
    }

    for (var map in mutableAccounts) {
      await _db.update(tableName, {'position': map['position']},
          where: 'accountId = ?', whereArgs: [map['accountId']]);
    }
  }

  Future<List<Map<String, dynamic>>> getAccountDataByType(
      int key, String columns, bool active,
      {String tableName = "profile0"}) async {
    await init();

    int activeValue = active ? 1 : 0;

    List<Map<String, dynamic>> result = await _db.query(
      tableName,
      columns: [columns],
      where: '${keys[key]} = ?',
      whereArgs: [activeValue],
    );

    return result;
  }

  Future<List<Map<String, dynamic>>> getAllAccounts(
      {String tableName = "profile0"}) async {
    await init();
    List<Map<String, dynamic>> result =
        await _db.query(tableName, columns: ['displayName', 'accountId']);

    return result;
  }

  Future<List<Map<String, dynamic>>> getFilteredAccountData() async {
    await init();
    List<Map<String, dynamic>> rawAccountData = await getAllAccounts();

    List<String> existingAccounts =
        await Directory(join(_directory.path, 'databases'))
            .list()
            .map((FileSystemEntity entity) => entity.path)
            .toList();

    List<Map<String, dynamic>> filteredData = [];

    for (Map<String, dynamic> currentData in rawAccountData) {
      String accountId = currentData['accountId'];
      if (!existingAccounts.any((path) => path.contains('$accountId.db'))) {
        continue;
      }
      filteredData.add(currentData);
    }

    return filteredData;
  }

  Future<List<String>> getTrackedSeasons(String accountId,
      {int limit = 1}) async {
    await init();
    List<String> tables = [];
    Database database = await openDatabase(accountId);
    List<Map<String, dynamic>> result = await database.rawQuery(
        "SELECT name from sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';");
    for (Map<String, dynamic> item in result) {
      if (limit > 0) {
        int columnCount = (await database
                .rawQuery('SELECT COUNT(*) as count FROM ${item["name"]}'))[0]
            ["count"] as int;
        if (columnCount < limit) {
          continue;
        }
      }
      tables.add(item["name"]);
    }

    tables.sort();

    return tables.reversed.toList();
  }

  Future<void> updatePlayerName(String accountId, String displayName,
      {String tableName = "profile0"}) async {
    await init();

    await _db.update(
      tableName,
      {'displayName': displayName},
      where: 'accountId = ?',
      whereArgs: [accountId],
    );
  }

  Future<void> updatePlayerNickName(String accountId, String nickName,
      {String tableName = "profile0"}) async {
    await init();

    await _db.update(
      tableName,
      {'nickName': nickName.isEmpty ? null : nickName},
      where: 'accountId = ?',
      whereArgs: [accountId],
    );
  }

  Future<String?> getPlayerNickName(String accountId,
      {String tableName = "profile0"}) async {
    await init();

    final result = await _db.query(
      tableName,
      columns: ["nickName"],
      where: 'accountId = ?',
      whereArgs: [accountId],
    );
    if (result.isEmpty) {
      return null;
    }
    return result.first["nickName"] as String?;
  }

  Future<bool> getPlayerIsExisiting(String accountId,
      {String tableName = "profile0"}) async {
    await init();
    final result = await _db
        .query(tableName, where: 'accountId = ?', whereArgs: [accountId]);

    return result.isNotEmpty ? true : false;
  }

  Future<int> getTrackedTableCount(String accountId, {int limit = 0}) async {
    Database database = await openDatabase(accountId);
    int trackedSeasonCount = 0;

    final result = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name != 'sqlite_sequence'");

    for (Map table in result) {
      List<Map> x = await database
          .rawQuery("SELECT COUNT(*) as count FROM ${table["name"]}");
      if (x.first["count"] >= limit) {
        trackedSeasonCount++;
      }
    }

    return trackedSeasonCount;
  }
}
