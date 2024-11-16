import 'package:flutter/material.dart';
import 'package:fortnite_ranked_tracker/components/custom_search_bar.dart';

import '../constants/constants.dart';
import '../core/rank_service.dart';
import 'dart:async';

import 'dart:math' as math;

class GraphBottomSheetContent extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final bool openSeasonSelection;

  const GraphBottomSheetContent(
      {super.key, required this.items, this.openSeasonSelection = false});

  @override
  GraphBottomSheetContentState createState() => GraphBottomSheetContentState();
}

class GraphBottomSheetContentState extends State<GraphBottomSheetContent> {
  late List<Map<String, dynamic>> items;
  bool trailingVisible = false;
  final SearchController _searchController = SearchController();
  String searchQuery = "";
  final GlobalKey editButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    items = widget.items;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.openSeasonSelection) {
        final editButton = editButtonKey.currentWidget as IconButton?;
        if (editButton != null && editButton.onPressed != null) {
          editButton.onPressed!();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredItems = items.where((item) {
      String displayName = item["displayName"] ?? "";
      return displayName.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomSearchBar(
              searchController: _searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            )),
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: filteredItems.length + 1,
            itemBuilder: (context, index) {
              if (index == filteredItems.length) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: FilledButton.icon(
                          onPressed: () async {
                            Map<String, dynamic>? result =
                                await _showAddItemScreen(context);
                            if (result != null) {
                              setState(() {
                                bool itemExists = items.any((item) =>
                                    item["accountId"] == result["accountId"] &&
                                    item["season"]["tableId"] ==
                                        result["season"]["tableId"]);

                                if (!itemExists) {
                                  items.add(result);
                                }
                              });
                            }
                          },
                          label: const Text('Add New Item'),
                          icon: const Icon(Icons.add),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.of(context).pop();
                              },
                              label: const Text('Cancel',
                                  style: TextStyle(color: Colors.red)),
                              icon: const Icon(
                                Icons.clear_rounded,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.of(context).pop(items);
                              },
                              label: const Text(
                                'Confirm',
                                style: TextStyle(color: Colors.green),
                              ),
                              icon: const Icon(
                                Icons.check_rounded,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                Map seasonInfo = filteredItems[index]["season"] ?? {};

                return ListTile(
                  title: Text(filteredItems[index]["displayName"]),
                  subtitle: seasonInfo.isNotEmpty
                      ? Text(
                          "${seasonInfo["tableName"]} - ${Constants.rankingTypeNames[seasonInfo["rankingType"]]}")
                      : null,
                  leading: IconButton(
                    icon: filteredItems[index]["visible"]
                        ? const Icon(
                            Icons.circle,
                          )
                        : const Icon(Icons.circle_outlined),
                    onPressed: () {
                      setState(() {
                        filteredItems[index]["visible"] =
                            !filteredItems[index]["visible"];
                      });
                    },
                    color: filteredItems[index]["color"],
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          onPressed: () {
                            _moveItem(index, true);
                          },
                          icon: const Icon(Icons.arrow_upward_rounded)),
                      IconButton(
                          onPressed: () {
                            _moveItem(index, false);
                          },
                          icon: const Icon(Icons.arrow_downward_rounded)),
                      IconButton(
                          key: index == 0 ? editButtonKey : null,
                          onPressed: () async {
                            int originalIndex =
                                items.indexOf(filteredItems[index]);

                            if (originalIndex != -1) {
                              Map<String, dynamic>? result =
                                  await _showAddItemScreen(
                                context,
                                accountId: items[originalIndex]["accountId"],
                                season: items[originalIndex]["season"] ?? {},
                              );

                              if (result != null) {
                                setState(() {
                                  items[originalIndex] = result;

                                  filteredItems[index] = result;
                                });
                              }
                            }
                          },
                          icon: const Icon(Icons.edit_rounded)),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {
                          setState(() {
                            int originalIndex =
                                items.indexOf(filteredItems[index]);

                            if (originalIndex != -1) {
                              items.removeAt(originalIndex);
                            }

                            filteredItems.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  void _moveItem(int index, bool moveUp) {
    final targetIndex = moveUp ? index - 1 : index + 1;

    if (targetIndex >= 0 && targetIndex < items.length) {
      final temp = items[index];
      items[index] = items[targetIndex];
      items[targetIndex] = temp;

      setState(() {});
    }
  }

  Future<Map<String, dynamic>> _prepareData(BuildContext context,
      String accountId, Map<String, dynamic> season) async {
    List<Map<String, dynamic>> data =
        await RankService().getAccountsWithSeasons(limit: 6, detailed: true);

    data = List.from(data);

    Map<String, String> accountDetails = {
      for (var item in data) item['accountId']: item['displayName']
    };

    return {
      'data': data,
      'accountDetails': accountDetails,
      'selectedAccountId': accountId.isNotEmpty ? accountId : null,
      'selectedSeason': season.isNotEmpty ? season : null,
    };
  }

  Future<Map<String, dynamic>?> _showAddItemScreen(BuildContext context,
      {String accountId = "", Map<String, dynamic>? season}) async {
    final dataFuture = _prepareData(context, accountId, season ?? {});

    return await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FutureBuilder<Map<String, dynamic>>(
          future: dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.9,
                  child: const Center(child: CircularProgressIndicator()));
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('No data available'));
            }

            final data = snapshot.data!;
            final List<Map<String, dynamic>> dataList = data['data'];
            final Map<String, String> accountDetails = data['accountDetails'];
            String? selectedAccountId = data['selectedAccountId'];
            Map<String, dynamic>? selectedSeason = data['selectedSeason'];
            String searchQuery = '';
            SearchController searchController = SearchController();
            ScrollController scrollController = ScrollController();

            return StatefulBuilder(
              builder: (context, setState) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (selectedAccountId != null) {
                    int index = dataList.indexWhere(
                        (item) => item["accountId"] == selectedAccountId);
                    if (index != -1) {
                      double itemHeight = 60.0;
                      double targetOffset = index * itemHeight;
                      if (targetOffset >
                          scrollController.position.maxScrollExtent) {
                        targetOffset =
                            scrollController.position.maxScrollExtent;
                      }
                      scrollController.jumpTo(targetOffset);
                    }
                  }
                });
                return Container(
                  height: MediaQuery.of(context).size.height * 0.9,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CustomSearchBar(
                        searchController: searchController,
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: ExpansionPanelList(
                            elevation: 4,
                            expandedHeaderPadding: const EdgeInsets.all(0),
                            children: dataList
                                .where((item) => item["displayName"]
                                    .toLowerCase()
                                    .contains(searchQuery.toLowerCase()))
                                .map((item) {
                              List<Map<String, dynamic>> filteredSeasons =
                                  (dataList
                                          .where((season) =>
                                              season["accountId"] ==
                                              item["accountId"])
                                          .toList()
                                          .first["trackedSeasons"] as List)
                                      .cast<Map<String, dynamic>>();

                              return ExpansionPanel(
                                backgroundColor:
                                    selectedAccountId == item["accountId"]
                                        ? Colors.blue.withOpacity(0.1)
                                        : Colors.transparent,
                                headerBuilder: (context, isExpanded) {
                                  return ListTile(
                                    title: Text(item["displayName"]),
                                    subtitle: Text(
                                        "Tracked Seasons: ${filteredSeasons.length}"),
                                    leading: CircleAvatar(
                                        backgroundImage:
                                            AssetImage(item["accountAvatar"])),
                                  );
                                },
                                body: Column(
                                  children: filteredSeasons.map((season) {
                                    bool isSelectedSeason =
                                        selectedSeason?["tableId"] ==
                                            season["tableId"];

                                    return ListTile(
                                      title: Text(season["tableName"]!),
                                      subtitle: Text(Constants.rankingTypeNames[
                                          season["rankingType"]]),
                                      trailing: isSelectedSeason
                                          ? const Icon(Icons.check,
                                              color: Colors.blue)
                                          : null,
                                      tileColor: isSelectedSeason
                                          ? Colors.blue.withOpacity(0.1)
                                          : Colors.transparent,
                                      onTap: () {
                                        setState(() {
                                          selectedSeason = season;
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                                isExpanded:
                                    selectedAccountId == item["accountId"],
                                canTapOnHeader: true,
                              );
                            }).toList(),
                            expansionCallback: (int index, bool isExpanded) {
                              String accountId = dataList
                                  .where((item) => item["displayName"]
                                      .toLowerCase()
                                      .contains(searchQuery.toLowerCase()))
                                  .elementAt(index)["accountId"];

                              setState(() {
                                selectedAccountId =
                                    isExpanded ? accountId : null;
                                selectedSeason = null;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          ElevatedButton(
                            onPressed: selectedAccountId != null &&
                                    selectedSeason != null
                                ? () {
                                    Navigator.of(context).pop({
                                      "visible": true,
                                      "displayName":
                                          accountDetails[selectedAccountId]!,
                                      "accountId": selectedAccountId,
                                      "season": selectedSeason,
                                      "color": Color(
                                              (math.Random().nextDouble() *
                                                      0xFFFFFF)
                                                  .toInt())
                                          .withOpacity(1.0),
                                    });
                                  }
                                : null,
                            child: const Text('Ok'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
