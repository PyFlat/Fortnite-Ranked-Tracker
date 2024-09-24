import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fortnite_ranked_tracker/components/custom_search_bar.dart';
import 'package:fortnite_ranked_tracker/constants/constants.dart';
import 'package:fortnite_ranked_tracker/core/tournament_service.dart';
import 'package:fortnite_ranked_tracker/components/tournament_stats_display.dart';
import 'package:fortnite_ranked_tracker/core/utils.dart';
import 'package:intl/intl.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../components/hoverable_leaderboard_item.dart';
import 'search_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen(
      {super.key, required this.talker, required this.tournamentWindow});

  final Talker talker;

  final Map<String, dynamic> tournamentWindow;

  @override
  LeaderboardScreenState createState() => LeaderboardScreenState();
}

class LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _allLeaderboardData = [];
  List<dynamic> _searchResults = [];
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isPaused = false;
  int _currentPage = -1;
  final int _totalPages = 100;
  final SearchController _searchController = SearchController();
  Future<void>? _initialData;

  @override
  void initState() {
    super.initState();
    _initialData = _loadInitialData();
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

  Future<void> _loadInitialData() async {
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _isLoading = true);

    try {
      final result = await TournamentService()
          .getEventLeaderboard(_currentPage, widget.tournamentWindow);

      final nonEmptyResults = (result["entries"] as List)
          .cast<Map<String, dynamic>>()
          .where((entry) => entry.isNotEmpty)
          .toList();

      if (nonEmptyResults.isNotEmpty) {
        setState(() {
          _allLeaderboardData = nonEmptyResults;
          _currentPage = (nonEmptyResults.length / 100).floor();
          _updateSearchQuery(_searchController.text);
        });

        if (_currentPage < _totalPages) {
          Future.microtask(_loadNextPage);
        }
      } else {
        setState(() {
          _currentPage = 0;
        });
        Future.microtask(_loadNextPage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || _currentPage >= _totalPages || _isPaused) return;

    setState(() => _isLoading = true);

    try {
      final result = await TournamentService()
          .getEventLeaderboard(_currentPage, widget.tournamentWindow);

      final nonEmptyResults = (result["entries"] as List)
          .cast<Map<String, dynamic>>()
          .where((entry) => entry.isNotEmpty)
          .toList();

      if (mounted) {
        if (_currentPage + 1 > result["totalPages"]) {
          setState(() {
            _currentPage = 101;
            return;
          });
        }
        setState(() {
          _allLeaderboardData = nonEmptyResults;
          _updateSearchQuery(_searchController.text);
          _currentPage++;
        });

        if (_currentPage < _totalPages) {
          Future.microtask(_loadNextPage);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _searchResults = _allLeaderboardData.where((entry) {
        if (entry.isEmpty) {
          return false;
        }
        final displayName =
            (entry['teamAccounts'] as Map).values.join(" + ").toLowerCase();
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
                talker: widget.talker,
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
                      text: 'Points: ${entry["pointsEarned"]}',
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
                    scoringRules: widget.tournamentWindow["scoringRules"],
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
    String regionName =
        getRegionNameByEventId(widget.tournamentWindow["eventId"])!;
    regionName = Constants.regions[regionName]!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.tournamentWindow["title"]} - Session ${widget.tournamentWindow["session"]}${widget.tournamentWindow["round"] > 0 ? " Round ${widget.tournamentWindow["round"]}" : ""} (${DateFormat("dd.MM.yyyy").format(DateTime.parse(widget.tournamentWindow["beginTime"]).toLocal())}) - $regionName',
        ),
      ),
      body: FutureBuilder(
          future: _initialData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Text(
                'Searching For Event Data...',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ));
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CustomSearchBar(
                    searchController: _searchController,
                    onChanged: _updateSearchQuery,
                  ),
                ),
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.all(16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 12),
                            Text('Loaded: ${_allLeaderboardData.length}',
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 12),
                            Text(
                              _isLoading
                                  ? 'Loading...(Page ${_currentPage + 1})'
                                  : _isPaused
                                      ? 'Paused...(Page ${_currentPage + 1})'
                                      : 'Finished',
                              style: TextStyle(
                                color: _isLoading
                                    ? Colors.orange
                                    : _isPaused
                                        ? Colors.red
                                        : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _currentPage = 0;
                                });
                                Future.microtask(_loadNextPage);
                              },
                              label: const Text("Refresh"),
                              icon: const Icon(Icons.refresh, size: 16),
                              style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8)),
                            ),
                            if (_isLoading)
                              const SizedBox(
                                width: 8,
                              ),
                            if (_isLoading || _isPaused)
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isPaused = !_isPaused;
                                  });
                                  Future.microtask(_loadNextPage);
                                },
                                label: Text(_isPaused ? "Continue" : "Pause"),
                                icon: Icon(
                                    _isPaused
                                        ? Icons.play_arrow_rounded
                                        : Icons.pause_rounded,
                                    size: 16),
                                style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8)),
                              ),
                            if (_currentPage != 0 &&
                                _currentPage <
                                    _allLeaderboardData.length ~/ 100)
                              const SizedBox(width: 8),
                            if (_currentPage != 0 &&
                                _currentPage <
                                    _allLeaderboardData.length ~/ 100)
                              ElevatedButton.icon(
                                onPressed: () {
                                  final nonEmptyResults =
                                      (_allLeaderboardData as List)
                                          .cast<Map<String, dynamic>>()
                                          .where((entry) => entry.isNotEmpty)
                                          .toList();

                                  setState(() {
                                    _isPaused = false;
                                  });

                                  _currentPage =
                                      (nonEmptyResults.length / 100).floor();
                                },
                                label: const Text("Stop"),
                                icon: const Icon(Icons.stop, size: 16),
                                style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8)),
                              ),
                          ],
                        ),
                      ],
                    ),
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
            );
          }),
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
