import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fortnite_ranked_tracker/components/custom_search_bar.dart';
import 'package:fortnite_ranked_tracker/core/rank_service.dart';
import 'package:fortnite_ranked_tracker/core/tournament_service.dart';
import 'package:fortnite_ranked_tracker/components/tournament_stats_display.dart';
import 'package:intl/intl.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../components/hoverable_leaderboard_item.dart';
import 'search_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen(
      {super.key, required this.talker, required this.tournamentWindow});

  final Talker talker;

  final TournamentWindowTemplate tournamentWindow;

  @override
  LeaderboardScreenState createState() => LeaderboardScreenState();
}

class LeaderboardScreenState extends State<LeaderboardScreen> {
  final List<dynamic> _allLeaderboardData = [];
  List<dynamic> _searchResults = [];
  String _searchQuery = '';
  bool _isLoading = false;
  int _currentPage = 0;
  final int _totalPages = 100;
  final SearchController _searchController = SearchController();

  @override
  void initState() {
    super.initState();
    _loadNextPage();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  }

  @override
  void dispose() {
    super.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp
    ]);
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || _currentPage >= _totalPages) return;

    setState(() => _isLoading = true);

    try {
      final result = await TournamentService()
          .getEventLeaderboard(_currentPage, widget.tournamentWindow);

      final allAccountIds = _extractAccountIds(result);
      final displayNames =
          await RankService().fetchByAccountId("", accountIds: allAccountIds);

      final modifiedEntries = _processEntries(result, displayNames);

      if (mounted) {
        if (_currentPage + 1 > result["totalPages"]) {
          setState(() {
            _currentPage = 101;
            return;
          });
        }
        setState(() {
          _allLeaderboardData.addAll(modifiedEntries);
          _updateSearchQuery(_searchController.text);
          _currentPage++;
        });
        Future.microtask(_loadNextPage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<String> _extractAccountIds(Map<String, dynamic> result) {
    return (result["entries"] as List).expand((entry) {
      return (entry["teamAccountIds"] as List<dynamic>)
          .map<String>((item) => item as String)
          .toList();
    }).toList();
  }

  List<Map<String, dynamic>> _processEntries(
      Map<String, dynamic> result, List<Map<String, dynamic>> displayNames) {
    final displayNamesMap = {
      for (var item in displayNames)
        item['accountId'] as String: item['displayName'] as String,
    };

    return (result["entries"] as List).map((entry) {
      final entryMap = Map<String, dynamic>.from(entry);
      final accountIds = (entryMap['teamAccountIds'] as List).cast<String>();
      final entryDisplayNames = accountIds.map((accountId) {
        return displayNamesMap[accountId] ?? 'Unknown';
      }).toList();
      entryMap['displayName'] = entryDisplayNames;
      return entryMap;
    }).toList();
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _searchResults = _allLeaderboardData.where((entry) {
        final displayName =
            (entry['displayName'] as List).join(" + ").toLowerCase();
        return displayName.contains(_searchQuery);
      }).toList();
    });
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
                      text: 'Points: ${entry["pointsEarned"]}',
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Divider(color: Colors.grey[700]),
                const SizedBox(height: 4.0),
                ..._buildUserInteractionButtons(entry),
                const SizedBox(height: 4.0),
                Divider(color: Colors.grey[700]),
                const SizedBox(height: 16.0),
                StatsDisplay(
                    entry: entry,
                    scoringRules: widget.tournamentWindow.scoringRules)
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

  List<Widget> _buildUserInteractionButtons(Map<String, dynamic> entry) {
    List<String> displayNames = List<String>.from(entry["displayName"]);
    List<String> teamAccountIds = List<String>.from(entry["teamAccountIds"]);

    return displayNames.asMap().entries.map((entry) {
      int index = entry.key;
      String name = entry.value;
      String accountId = teamAccountIds[index];

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(color: Colors.grey.shade300, fontSize: 16.0),
            ),
          ),
          IconButton(
            icon: Icon(Icons.open_in_new_rounded, color: Colors.grey.shade300),
            onPressed: () {
              _openUser(name, accountId);
            },
          ),
        ],
      );
    }).toList();
  }

  void _openUser(String displayName, String accountId) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SearchScreen(
                accountId: accountId,
                displayName: displayName,
                talker: widget.talker,
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.tournamentWindow.title} - Session ${widget.tournamentWindow.session}${widget.tournamentWindow.round > 0 ? " Round ${widget.tournamentWindow.round}" : ""} (${DateFormat("dd.MM.yyyy").format(widget.tournamentWindow.beginTime.toLocal())}) - ${widget.tournamentWindow.regionTrivial}',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomSearchBar(
              searchController: _searchController,
              onChanged: _updateSearchQuery,
            ),
          ),
          if (_searchResults.isEmpty && _isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          if (_searchResults.isNotEmpty || !_isLoading)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                prototypeItem: const SizedBox(height: 120),
                itemBuilder: (context, index) {
                  final entry = _searchResults[index];
                  return _buildLeaderboardItem(entry, index);
                },
              ),
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
