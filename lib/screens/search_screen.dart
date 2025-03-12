import 'package:flutter/material.dart';
import 'package:fortnite_ranked_tracker/components/account_search_widget.dart';
import 'package:fortnite_ranked_tracker/components/search_card.dart';

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
  String? _selectedAccountId;
  String? _selectedDisplayName;

  bool searchRunning = false;
  bool firstSearchDone = false;
  String searchTerm = "";
  GlobalKey searchCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectedAccountId = widget.accountId;
    _selectedDisplayName = widget.displayName;
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
                Center(child: AccountSearchWidget(
                  onAccountSelected: (accountId, displayName, _) {
                    setState(() {
                      _selectedAccountId = accountId;
                      _selectedDisplayName = displayName;
                    });
                    searchCardKey = GlobalKey();
                  },
                )),
              ],
            ),
            if (_selectedAccountId != null)
              Expanded(
                  child: Center(
                      child: SearchCard(
                key: searchCardKey,
                accountId: _selectedAccountId!,
                displayName: _selectedDisplayName!,
              )))
          ],
        ),
      ),
    );
  }
}
