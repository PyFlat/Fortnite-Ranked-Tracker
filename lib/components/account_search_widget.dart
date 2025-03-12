import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../core/rank_service.dart';

class AccountSearchWidget extends StatefulWidget {
  final void Function(String accountId, String displayName, String platform)
      onAccountSelected;

  const AccountSearchWidget({super.key, required this.onAccountSelected});

  @override
  AccountSearchWidgetState createState() => AccountSearchWidgetState();
}

class AccountSearchWidgetState extends State<AccountSearchWidget> {
  final _searchController = SearchController();

  bool searchRunning = false;
  bool firstSearchDone = false;
  String searchTerm = "";
  late Iterable<Widget> _lastOptions = <Widget>[];

  void _refreshSuggestions() {
    final String text = _searchController.text;
    _searchController.text = "";
    _searchController.text = text;
  }

  Future<List<Map<String, dynamic>>?> _search(String query) async {
    if (query.isEmpty || (query.length > 16 && query.length != 32)) {
      return [];
    }

    List<Map<String, dynamic>> result = await RankService()
        .searchByQuery(query, onlyAccountId: query.length == 32);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return SearchAnchor.bar(
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

        _lastOptions = List<ListTile>.generate(results.length, (int index) {
          final Map<String, dynamic> item = results[index];
          return ListTile(
            leading: SvgPicture.asset(
              "assets/icons/${item['platform']}.svg",
              colorFilter:
                  const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            title: Text(item['displayName'] ?? ''),
            onTap: () {
              widget.onAccountSelected(
                  item['accountId'], item['displayName'], item['platform']);
              _searchController.closeView(null);
            },
          );
        });
        searchRunning = false;
        _refreshSuggestions();
      },
      suggestionsBuilder:
          (BuildContext context, SearchController controller) async {
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ];
        }
        return _lastOptions;
      },
    );
  }
}
