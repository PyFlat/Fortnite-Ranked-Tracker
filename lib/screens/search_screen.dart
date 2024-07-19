import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fortnite_ranked_tracker/components/search_card.dart';
import 'package:provider/provider.dart';

import 'package:fortnite_ranked_tracker/constants/endpoints.dart';
import 'package:fortnite_ranked_tracker/core/api_service.dart';
import '../core/auth_provider.dart';

const Duration fakeAPIDuration = Duration(seconds: 1);
const Duration debounceDuration = Duration(milliseconds: 500);

class SearchScreen extends StatefulWidget {
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String? _currentQuery;
  String? _selectedDisplayName;
  late Iterable<Widget> _lastOptions = <Widget>[];
  late final _Debounceable<List<Map<String, String>>?, String> _debouncedSearch;

  Future<List<Map<String, String>>?> _search(String query) async {
    _currentQuery = query;

    // In a real application, there should be some error handling here.
    final List<Map<String, String>> results =
        await _API.search(_currentQuery!, context);

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
                              _selectedDisplayName = item['accountId'];
                            });
                            //controller.closeView(null);
                          },
                        );
                      });

                      return _lastOptions;
                    },
                  ),
                ),
              ],
            ),
            if (_selectedDisplayName != null) const Center(child: SearchCard())
          ],
        ),
      ),
    );
  }
}

class _API {
  static Future<List<Map<String, String>>> search(
      String query, BuildContext buildContext) async {
    final authProvider = Provider.of<AuthProvider>(buildContext, listen: false);
    final headerAuthorization = "Bearer ${authProvider.accessToken}";

    if (query.isEmpty || (query.length > 16 && query.length != 32)) {
      return [];
    }

    Future<List<Map<String, String>>> fetchResults(String platform) async {
      final pathParams = ["49a809c144844feea10b90b60b27d8bc", platform, query];
      final url = ApiService.interpolate(Endpoints.userSearch, pathParams);
      final response = await ApiService.getData(url, headerAuthorization);
      if (!response.contains("StatusCode:")) {
        final List<dynamic> jsonObject = jsonDecode(response);

        return jsonObject.map((item) {
          final match = item['matches'][0];
          return {
            'accountId': item["accountId"] as String,
            'platform': match["platform"] as String,
            'displayName': match["value"] as String,
          };
        }).toList();
      }
      return [];
    }

    Future<List<Map<String, String>>> fetchAccountId(String accountId) async {
      final url = ApiService.interpolate(Endpoints.userByAccId, [accountId]);
      final response = await ApiService.getData(url, headerAuthorization);
      Map<String, dynamic> jsonObj = jsonDecode(response)[0];
      if (jsonObj.containsKey("displayName")) {
        return [
          {
            'accountId': jsonObj["id"] as String,
            'platform': "epic",
            'displayName': jsonObj["displayName"] as String
          }
        ];
      } else {
        if (jsonObj["externalAuths"].containsKey("psn")) {
          return [
            {
              'accountId': jsonObj["id"] as String,
              'platform': "psn",
              'displayName': jsonObj["externalAuths"]["psn"]
                  ["externalDisplayName"] as String
            }
          ];
        } else if (jsonObj["externalAuths"].containsKey("xbl")) {
          return [
            {
              'accountId': jsonObj["id"] as String,
              'platform': "xbl",
              'displayName': jsonObj["externalAuths"]["xbl"]
                  ["externalDisplayName"] as String
            }
          ];
        }
      }
      return [];
    }

    Future<Map<String, String>> fetchDisplayNameByPlatform(
        String displayName, String platform) async {
      String url;
      if (platform != "epic") {
        final pathParams = [platform, displayName];
        url = ApiService.interpolate(Endpoints.userByNameExt, pathParams);
      } else {
        final pathParams = [displayName];
        url = ApiService.interpolate(Endpoints.userByName, pathParams);
      }
      final response = await ApiService.getData(url, headerAuthorization);

      if (!response.contains("StatusCode:") && response != "[]") {
        final dynamic jsonObject = jsonDecode(response);
        if (platform == "epic") {
          return {
            "accountId": jsonObject["id"] as String,
            "displayName": jsonObject["displayName"] as String,
            "platform": platform
          };
        } else {
          String displayName;
          if (jsonObject[0].containsKey("displayName")) {
            displayName = jsonObject[0]["displayName"];
          } else {
            displayName =
                jsonObject[0]["externalAuths"][platform]["externalDisplayName"];
          }
          return {
            "accountId": jsonObject[0]["id"] as String,
            "displayName": displayName,
            "platform": platform
          };
        }
      } else {
        return {};
      }
    }

    Future<List<Map<String, String>>> fetchDisplayName(
        String displayName) async {
      Map<String, String> epic =
          await fetchDisplayNameByPlatform(displayName, "epic");
      Map<String, String> psn =
          await fetchDisplayNameByPlatform(displayName, "psn");
      Map<String, String> xbl =
          await fetchDisplayNameByPlatform(displayName, "xbl");

      if (psn.isNotEmpty &&
          epic.isNotEmpty &&
          psn["accountId"] == epic["accountId"]) {
        psn = {};
      }
      if (xbl.isNotEmpty) {
        if (psn.isNotEmpty && xbl["accountId"] == psn["accountId"]) {
          xbl = {};
        }
        if (epic.isNotEmpty && xbl["accountId"] == epic["accountId"]) {
          xbl = {};
        }
      }

      return [epic, psn, xbl].where((map) => map.isNotEmpty).toList();
    }

    if (query.length == 32) {
      return await fetchAccountId(query);
    }
    final epicResults = await fetchResults("epic");
    final psnResults = await fetchResults("psn");
    final xboxResults = await fetchResults("xbl");

    final allResults = [...epicResults, ...psnResults, ...xboxResults];

    if (allResults.isEmpty) {
      dynamic result = await fetchDisplayName(query);
      return result;
    }

    final uniqueResults = <String, Map<String, String>>{};

    for (var result in allResults) {
      final accountId = result['accountId']!;
      if (!uniqueResults.containsKey(accountId)) {
        uniqueResults[accountId] = result;
      }
    }

    return uniqueResults.values.toList();
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
