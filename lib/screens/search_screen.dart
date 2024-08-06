import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fortnite_ranked_tracker/components/search_card.dart';
import 'package:fortnite_ranked_tracker/core/rank_service.dart';

const Duration fakeAPIDuration = Duration(seconds: 1);
const Duration debounceDuration = Duration(seconds: 2);

class SearchScreen extends StatefulWidget {
  final String? accountId;
  final String? displayName;
  const SearchScreen({super.key, this.accountId, this.displayName});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String? _currentQuery;
  String? _selectedAccountId;
  String? _selectedDisplayName;
  late Iterable<Widget> _lastOptions = <Widget>[];
  final SearchController _searchController = SearchController();
  bool searchRunning = false;
  String searchTerm = "";

  Future<List<Map<String, String>>?> _search(String query) async {
    _currentQuery = query;

    // In a real application, there should be some error handling here.
    final List<Map<String, String>> results =
        await RankService().search(_currentQuery!);

    // If another search happened after this one, throw away these results.
    if (_currentQuery != query) {
      return null;
    }
    _currentQuery = null;

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
                      searchTerm = value;
                      searchRunning = true;
                      _refreshSuggestions();
                      final List<Map<String, String>>? results =
                          (await _search(value))?.toList();
                      if (results == null) {
                        return;
                      }

                      _lastOptions =
                          List<ListTile>.generate(results.length, (int index) {
                        final Map<String, String> item = results[index];
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
                accountId: _selectedAccountId,
                displayName: _selectedDisplayName,
              )))
          ],
        ),
      ),
    );
  }
}
