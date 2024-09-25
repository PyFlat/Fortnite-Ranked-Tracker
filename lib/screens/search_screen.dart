import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fortnite_ranked_tracker/components/search_card.dart';
import 'package:fortnite_ranked_tracker/core/rank_service.dart';
import 'package:talker_flutter/talker_flutter.dart';

const Duration fakeAPIDuration = Duration(seconds: 1);
const Duration debounceDuration = Duration(seconds: 2);

class SearchScreen extends StatefulWidget {
  final String? accountId;
  final String? displayName;
  final Talker talker;
  const SearchScreen(
      {super.key, this.accountId, this.displayName, required this.talker});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String? _selectedAccountId;
  String? _selectedDisplayName;
  late Iterable<Widget> _lastOptions = <Widget>[];
  final SearchController _searchController = SearchController();
  bool searchRunning = false;
  bool firstSearchDone = false;
  String searchTerm = "";
  final GlobalKey searchCardKey = GlobalKey();

  Future<List<Map<String, dynamic>>?> _search(String query) async {
    final List<Map<String, dynamic>> results =
        await RankService().search(query);

    return results;
  }

  @override
  void initState() {
    super.initState();
    _selectedAccountId = widget.accountId;
    _selectedDisplayName = widget.displayName;
  }

  void _refreshSuggestions() {
    final String text = _searchController.text;
    _searchController.text = "";
    _searchController.text = text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Column(
              children: [
                Center(
                  child: SearchAnchor.bar(
                    barHintText: "Type name to search",
                    searchController: _searchController,
                    onChanged: (value) {
                      if (searchRunning) {
                        _searchController.text = searchTerm;
                      }
                    },
                    onSubmitted: (value) async {
                      if (searchRunning) {
                        return;
                      }
                      if (!firstSearchDone) {
                        firstSearchDone = true;
                      }
                      searchTerm = value;
                      searchRunning = true;

                      _refreshSuggestions();
                      final List<Map<String, dynamic>>? results =
                          (await _search(value))?.toList();
                      if (results == null) {
                        return;
                      }

                      _lastOptions =
                          List<ListTile>.generate(results.length, (int index) {
                        final Map<String, dynamic> item = results[index];
                        return ListTile(
                          leading: SvgPicture.asset(
                            "assets/icons/${item['platform']}.svg",
                            colorFilter: const ColorFilter.mode(
                                Colors.white, BlendMode.srcIn),
                          ),
                          title: Text(item['displayName'] ?? ''),
                          onTap: () {
                            setState(() {
                              _selectedAccountId = item['accountId'];
                              _selectedDisplayName = item['displayName'];
                            });
                            _searchController.closeView(null);
                          },
                        );
                      });
                      searchRunning = false;
                      _refreshSuggestions();
                    },
                    suggestionsBuilder: (BuildContext context,
                        SearchController controller) async {
                      if (searchRunning) {
                        return [
                          const Center(
                            child: LinearProgressIndicator(),
                          )
                        ];
                      }
                      if (_lastOptions.isEmpty && firstSearchDone) {
                        return [
                          const SizedBox(
                            height: 20,
                          ),
                          const Center(
                            child: Text(
                              "No user found",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ];
                      }
                      return _lastOptions;
                    },
                  ),
                ),
              ],
            ),
            if (_selectedAccountId != null)
              Expanded(
                  child: Center(
                      child: SearchCard(
                key: searchCardKey,
                accountId: _selectedAccountId!,
                displayName: _selectedDisplayName!,
                talker: widget.talker,
              )))
          ],
        ),
      ),
    );
  }
}
