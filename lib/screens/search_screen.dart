import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fortnite_ranked_tracker/components/search_card.dart';
import 'package:fortnite_ranked_tracker/core/rank_service.dart';

const Duration fakeAPIDuration = Duration(seconds: 1);
const Duration debounceDuration = Duration(milliseconds: 500);

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
  late final _Debounceable<List<Map<String, String>>?, String> _debouncedSearch;

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
    _debouncedSearch = _debounce<List<Map<String, String>>?, String>(_search);
    _selectedAccountId = widget.accountId;
    _selectedDisplayName = widget.displayName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search'),
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
                    suggestionsBuilder: (BuildContext context,
                        SearchController controller) async {
                      final List<Map<String, String>>? results =
                          (await _debouncedSearch(controller.text))?.toList();
                      if (results == null) {
                        return _lastOptions;
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
                            controller.closeView(null);
                          },
                        );
                      });

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

typedef _Debounceable<S, T> = Future<S?> Function(T parameter);

_Debounceable<S, T> _debounce<S, T>(_Debounceable<S?, T> function) {
  _DebounceTimer? debounceTimer;

  return (T parameter) async {
    if (debounceTimer != null && !debounceTimer!.isCompleted) {
      debounceTimer!.cancel();
    }
    debounceTimer = _DebounceTimer();
    try {
      await debounceTimer!.future;
    } catch (error) {
      if (error is _CancelException) {
        return null;
      }
      rethrow;
    }
    return function(parameter);
  };
}

class _DebounceTimer {
  _DebounceTimer() {
    _timer = Timer(debounceDuration, _onComplete);
  }

  late final Timer _timer;
  final Completer<void> _completer = Completer<void>();

  void _onComplete() {
    _completer.complete();
  }

  Future<void> get future => _completer.future;

  bool get isCompleted => _completer.isCompleted;

  void cancel() {
    _timer.cancel();
    _completer.completeError(const _CancelException());
  }
}

class _CancelException implements Exception {
  const _CancelException();
}
