import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fortnite_ranked_tracker/components/custom_search_bar.dart';
import 'package:fortnite_ranked_tracker/constants/constants.dart';
import 'package:fortnite_ranked_tracker/components/tournament_stats_display.dart';
import 'package:fortnite_ranked_tracker/core/rank_service.dart';

import '../components/group_selection_modal.dart';
import '../components/hoverable_leaderboard_item.dart';
import '../components/tournament_details_sheet.dart';
import 'search_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen(
      {super.key,
      required this.tournamentWindow,
      required this.filteredSessions,
      required this.cumulativeSessions,
      required this.metadata,
      required this.region});

  final Map<String, dynamic> tournamentWindow;

  final List<Map<String, dynamic>> filteredSessions;
  final List<Map<String, dynamic>> cumulativeSessions;

  final Map<String, dynamic> metadata;

  final String region;

  @override
  LeaderboardScreenState createState() => LeaderboardScreenState();
}

class LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _allLeaderboardData = [];
  Map<String, List<Map<String, dynamic>>> _scoringRules = {};
  List<dynamic> _searchResults = [];

  List<Map<String, dynamic>> groups = [];
  String _searchQuery = '';
  final SearchController _searchController = SearchController();
  Future<void>? _initialData;
  bool autoUpdate = false;
  Timer? _autoUpdateTimer;

  @override
  void initState() {
    super.initState();
    _initialData = _loadLeadboardData();
    _startAutoUpdateTimer();
  }

  @override
  void dispose() {
    _autoUpdateTimer?.cancel();
    super.dispose();
  }

  void _startAutoUpdateTimer() {
    _autoUpdateTimer?.cancel();
    if (autoUpdate) {
      _autoUpdateTimer = Timer.periodic(Duration(seconds: 5), (timer) {
        setState(() {
          _initialData = _fetchLeaderboardData();
        });
      });
    }
  }

  Future<void> _loadLeadboardData() async {
    final String eventId = widget.tournamentWindow["eventId"];
    final String windowId = widget.tournamentWindow["windowId"];

    _scoringRules = await RankService().getEventScoringRules(eventId, windowId);

    _allLeaderboardData =
        await RankService().getEventLeaderboard(eventId, windowId);

    _updateSearchQuery('');
  }

  Future<void> _fetchLeaderboardData() async {
    if (groups.isEmpty || groups.every((element) => !element["selected"])) {
      _allLeaderboardData = await RankService().fetchEventLeaderboard(
          widget.tournamentWindow["eventId"],
          widget.tournamentWindow["windowId"]);
    } else {
      final selectedGroup = groups.firstWhere((element) => element["selected"]);

      final accountIds = (selectedGroup["members"] as List)
          .map((element) => element["accountId"] as String)
          .toList();
      _allLeaderboardData = await RankService()
          .fetchEventLeaderboardWithAccountIds(
              widget.tournamentWindow["eventId"],
              widget.tournamentWindow["windowId"],
              accountIds);
    }

    _updateSearchQuery(_searchController.text);
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();

      if ((_searchQuery.trim().isEmpty && _searchQuery.isNotEmpty) ||
          _searchQuery.trim() == '+') {
        _searchResults = [];
        return;
      }

      _searchResults = _allLeaderboardData.where((entry) {
        if (entry.isEmpty) {
          return false;
        }
        final displayName =
            (entry['accounts'] as List).join(" + ").toLowerCase();
        return displayName.contains(_searchQuery);
      }).toList();
    });
  }

  void _openUser(String displayName, String accountId) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SearchScreen(
                accountId: accountId,
                displayName: displayName,
              )),
    );
  }

  void _showDetails(dynamic entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildText(
                      text: 'Rank: ${entry["rank"]}',
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                    _buildText(
                      text: 'Points: ${entry["points"]}',
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Divider(color: Colors.grey[700]),
                const SizedBox(height: 16.0),
                StatsDisplay(
                    entry: entry,
                    eventWindow: widget.tournamentWindow,
                    scoringRules: _scoringRules,
                    openUser: _openUser)
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildText({
    required String text,
    double fontSize = 14.0,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.black,
    Icon? icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          icon,
          const SizedBox(width: 8.0),
        ],
        Text(
          text,
          style: TextStyle(
              fontSize: fontSize, fontWeight: fontWeight, color: color),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final regionName = Constants.regions[widget.region]!;

    DateTime beginTime = DateTime.parse(widget.tournamentWindow["beginTime"]);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.metadata['longTitle']} ${widget.tournamentWindow["windowName"]}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Row(
            spacing: 4,
            children: [
              Text("Auto Update"),
              Switch(
                  value: autoUpdate,
                  onChanged: (value) {
                    setState(() {
                      autoUpdate = value;
                      _startAutoUpdateTimer();
                    });
                  })
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () async {
                final data = await showModalBottomSheet<int>(
                  context: context,
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.9,
                      child: TournamentDetailsSheet(
                          regionName: regionName,
                          title: widget.metadata['longTitle'],
                          windowName: widget.tournamentWindow["windowName"],
                          beginTime: widget.tournamentWindow['beginTime'],
                          endTime: widget.tournamentWindow['endTime'],
                          id: widget.tournamentWindow["id"],
                          isCumulative: ["cumulative", "floating"]
                              .contains(widget.tournamentWindow["eventId"]),
                          showCumulative:
                              widget.tournamentWindow["cumulative"] != null,
                          cumulativeId: widget.tournamentWindow["cumulative"],
                          scoringRules: _scoringRules,
                          allLeaderboardData: _allLeaderboardData,
                          eventId: widget.tournamentWindow["eventId"],
                          windowId: widget.tournamentWindow["windowId"]),
                    );
                  },
                );
                if (data != null) {
                  if (data <= 1 && context.mounted) {
                    bool cumulative = data == 1 ? true : false;
                    Navigator.pop(context, [
                      false,
                      widget.tournamentWindow["cumulative"],
                      cumulative,
                    ]);
                  } else if (data == 2 && context.mounted) {
                    Navigator.pop(context, [true]);
                  }
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 8,
          children: [
            FloatingActionButton.extended(
              heroTag: "refresh",
              onPressed: () {
                setState(() {
                  _initialData = _fetchLeaderboardData();
                });
              },
              icon: Icon(Icons.refresh_rounded),
              label: Text("Refresh"),
            ),
            FloatingActionButton.extended(
              heroTag: "groups",
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.9,
                      child: GroupSelectionModal(
                        onGroupsChanged: (List<Map<String, dynamic>> groups) {
                          setState(() {
                            this.groups = groups;
                          });
                        },
                      ),
                    );
                  },
                );
              },
              icon: Icon(Icons.groups_rounded),
              label: Text("Groups"),
            ),
          ]),
      body: FutureBuilder(
          future: _initialData,
          builder: (context, snapshot) {
            if (beginTime.isAfter(DateTime.now())) {
              return _buildCenteredMessage(
                message: 'Event has not started yet...',
                icon: Icons.event,
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                _allLeaderboardData.isEmpty) {
              return _buildCenteredMessage(
                message: 'Searching For Event Data...',
                icon: Icons.search,
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                          child: CustomSearchBar(
                        searchController: _searchController,
                        onChanged: _updateSearchQuery,
                      )),
                    ],
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      prototypeItem: const SizedBox(height: 90),
                      itemBuilder: (context, index) {
                        final entry = _searchResults[index];
                        return _buildLeaderboardItem(entry, index);
                      },
                    ),
                  ),
                if (_searchResults.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _allLeaderboardData.isEmpty
                          ? "This event hasn't been fetched yet."
                          : "No match was found with the search query.",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            );
          }),
    );
  }

  Widget _buildCenteredMessage(
      {required String message, required IconData icon}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.grey[300],
              shadows: [
                Shadow(
                    offset: Offset(0, 2), blurRadius: 4, color: Colors.black38)
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(dynamic entry, int index) {
    return HoverableLeaderboardItem(
      entry: entry,
      index: index,
      onTap: () => _showDetails(entry),
    );
  }
}
