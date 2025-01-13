import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fortnite_ranked_tracker/components/custom_search_bar.dart';
import 'package:fortnite_ranked_tracker/constants/constants.dart';
import 'package:fortnite_ranked_tracker/components/tournament_stats_display.dart';
import 'package:fortnite_ranked_tracker/core/rank_service.dart';
import 'package:intl/intl.dart';

import '../components/hoverable_leaderboard_item.dart';
import 'search_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen(
      {super.key,
      required this.tournamentWindow,
      required this.metadata,
      required this.region});

  final Map<String, dynamic> tournamentWindow;

  final Map<String, dynamic> metadata;

  final String region;

  @override
  LeaderboardScreenState createState() => LeaderboardScreenState();
}

class LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _allLeaderboardData = [];
  List<dynamic> _searchResults = [];
  String _searchQuery = '';
  final SearchController _searchController = SearchController();
  Future<void>? _initialData;

  bool _showCheckmark = false;

  @override
  void initState() {
    super.initState();
    _initialData = _loadLeadboardData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadLeadboardData() async {
    _allLeaderboardData = await RankService().getEventLeaderboard(
        widget.tournamentWindow["eventId"],
        widget.tournamentWindow["windowId"]);

    _updateSearchQuery('');
  }

  Future<void> _fetchLeaderboardData() async {
    _allLeaderboardData = await RankService().fetchEventLeaderboard(
        widget.tournamentWindow["eventId"],
        widget.tournamentWindow["windowId"]);

    _updateSearchQuery('');
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

  Widget buildTournamentDetails() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              runSpacing: 16,
              spacing: 32,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  label: Text("Rules & Prices"),
                  icon: Icon(Icons.info, size: 20, color: Colors.grey),
                ),
                TextButton.icon(
                  label: Text("Tournament ID"),
                  icon: _showCheckmark
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : Icon(Icons.copy, size: 20, color: Colors.grey),
                  onPressed: () async {
                    Clipboard.setData(
                        ClipboardData(text: widget.tournamentWindow["id"]));
                    setState(() {
                      _showCheckmark = true;
                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) {
                          setState(() {
                            _showCheckmark = false;
                          });
                        }
                      });
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomSearchBar(
                    searchController: _searchController,
                    onChanged: _updateSearchQuery,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final regionName = Constants.regions[widget.region]!;
    final eventDate = DateFormat('dd.MM.yyyy HH:mm')
        .format(DateTime.parse(widget.tournamentWindow['beginTime']).toLocal());

    DateTime beginTime = DateTime.parse(widget.tournamentWindow["beginTime"]);
    return Scaffold(
      appBar: AppBar(
          title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 32,
        children: [
          Column(
            children: [
              Text(
                widget.metadata['longTitle'],
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${widget.tournamentWindow["windowName"]}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Column(
            children: [
              Text(
                regionName,
                style: TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                eventDate,
                style: TextStyle(fontSize: 16),
              )
            ],
          ),
        ],
      )),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            setState(() {
              _initialData = _fetchLeaderboardData();
            });
          },
          icon: Icon(Icons.refresh_rounded),
          label: Text("Refresh")),
      body: FutureBuilder(
          future: _initialData,
          builder: (context, snapshot) {
            if (beginTime.isAfter(DateTime.now())) {
              return _buildCenteredMessage(
                message: 'Event has not started yet...',
                icon: Icons.event,
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildCenteredMessage(
                message: 'Searching For Event Data...',
                icon: Icons.search,
              );
            }

            return Column(
              children: [
                buildTournamentDetails(),
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
