import 'dart:collection';

import 'package:darq/darq.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paged_datatable/paged_datatable.dart';
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
  final tableController = PagedDataTableController<String, Post>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Database of ${widget.account["displayName"]}"),
        ),
        body: PagedDataTableTheme(
          data: PagedDataTableThemeData(
              backgroundColor: Color(0x333138),
              cellTextStyle: TextStyle(color: Colors.white),
              headerTextStyle: TextStyle(color: Colors.white)),
          child: PagedDataTable<String, Post>(
            configuration: const PagedDataTableConfiguration(),
            initialPageSize: 100,
            controller: tableController,
            pageSizes: const [10, 20, 50, 100, 200, 1000],
            columns: [
              TableColumn(
                  cellBuilder: (context, item, index) => Text(
                        item.id.toString(),
                      ),
                  sortable: true,
                  id: 'id',
                  title: const Text("Match"),
                  size: const MaxColumnSize(
                      FractionalColumnSize(.15), FixedColumnSize(100))),
              TableColumn(
                  cellBuilder: (context, item, index) => Text(
                      DateFormat('dd.MM.yyyy HH:mm:ss').format(item.datetime)),
                  title: const Text("Datetime"),
                  size: const MaxColumnSize(
                      FractionalColumnSize(.25), FixedColumnSize(100))),
              TableColumn(
                  cellBuilder: (context, item, index) =>
                      Text(item.rank.toString()),
                  title: const Text("Rank"),
                  size: const MaxColumnSize(
                      FractionalColumnSize(.15), FixedColumnSize(50))),
              TableColumn(
                  cellBuilder: (context, item, index) =>
                      Text(item.rankProgress.toString()),
                  title: const Text("Progress"),
                  size: const MaxColumnSize(
                      FractionalColumnSize(.15), FixedColumnSize(100))),
              TableColumn(
                  cellBuilder: (context, item, index) =>
                      Text(item.matchId.toString()),
                  title: const Text("Daily Match ID"),
                  sortable: true,
                  id: 'match-id',
                  size: const MaxColumnSize(
                      FractionalColumnSize(.15), FixedColumnSize(100))),
              TableColumn(
                  cellBuilder: (context, item, index) =>
                      Text(item.totalProgress.toString()),
                  title: const Text("Total Progress"),
                  sortable: true,
                  id: 'total-progress',
                  size: const MaxColumnSize(
                      FractionalColumnSize(.15), FixedColumnSize(100))),
            ],
            fetcher: (pageSize, sortModel, filterModel, pageToken) async {
              final result = await PostsRepository.getPosts(
                  sortDescending: sortModel?.descending ?? false,
                  sortBy: sortModel?.fieldName,
                  pageSize: pageSize,
                  pageToken: pageToken,
                  accountId: widget.account["accountId"]);
              return (result.items, result.nextPageToken);
            },
          ),
        ));
  }
}

class Post {
  final int id;
  DateTime datetime;
  String rank;
  int rankProgress;
  int matchId;
  int totalProgress;

  Post({
    required this.id,
    required this.datetime,
    required this.rank,
    required this.rankProgress,
    required this.matchId,
    required this.totalProgress,
  });

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is Post ? other.id == id : false;
}

class PostsRepository {
  PostsRepository._();

  static final List<Post> _backend = [];

  static fetchData(String accountId) async {
    final DataBase database = DataBase();

    _backend.clear();

    Database db = await database.openDatabase(accountId);
    List<Map<String, dynamic>> result =
        await db.rawQuery("SELECT * FROM chapter_5_season_3_br");
    _backend.addAll(List.generate(result.length, (int index) {
      return Post(
          id: result[index]["id"],
          datetime: DateTime.parse(result[index]["datetime"]),
          rank: result[index]["rank"],
          rankProgress: result[index]["progress"],
          matchId: result[index]["daily_match_id"],
          totalProgress: result[index]["total_progress"]);
    }));
  }

  static Future<PaginatedList<Post>> getPosts(
      {required int pageSize,
      required String? pageToken,
      required String accountId,
      bool? status,
      DateTimeRange? between,
      String? authorName,
      String? searchQuery,
      String? sortBy,
      bool sortDescending = false}) async {
    int nextId = pageToken == null ? 0 : int.tryParse(pageToken) ?? 1;

    await fetchData(accountId);

    Iterable<Post> query = _backend;

    if (sortBy == null) {
      query = query.orderBy((element) => element.id);
    } else {
      switch (sortBy) {
        case "id":
          query = sortDescending
              ? query.orderByDescending((element) => element.id)
              : query.orderBy((element) => element.id);
          break;

        case "progress":
          query = sortDescending
              ? query.orderByDescending((element) => element.rankProgress)
              : query.orderBy((element) => element.rankProgress);
          break;

        case "match-id":
          query = sortDescending
              ? query.orderByDescending((element) => element.matchId)
              : query.orderBy((element) => element.matchId);
          break;

        case "total-progress":
          query = sortDescending
              ? query.orderByDescending((element) => element.totalProgress)
              : query.orderBy((element) => element.totalProgress);
          break;
      }
    }

    query = query.where((element) => element.id >= nextId);

    var resultSet = query.take(pageSize + 1).toList();
    String? nextPageToken;
    if (resultSet.length == pageSize + 1) {
      Post lastPost = resultSet.removeLast();
      nextPageToken = lastPost.id.toString();
    }

    return PaginatedList(items: resultSet, nextPageToken: nextPageToken);
  }
}

class PaginatedList<T> {
  final Iterable<T> _items;
  final String? _nextPageToken;

  List<T> get items => UnmodifiableListView(_items);
  String? get nextPageToken => _nextPageToken;

  PaginatedList({required Iterable<T> items, String? nextPageToken})
      : _items = items,
        _nextPageToken = nextPageToken;
}
