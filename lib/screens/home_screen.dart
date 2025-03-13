import 'dart:async';

import 'package:fortnite_ranked_tracker/components/home_page_edit_sheet.dart';
import 'package:fortnite_ranked_tracker/core/avatar_manager.dart';
import 'package:fortnite_ranked_tracker/core/socket_service.dart';

import '../core/rank_service.dart';

import '../components/dashboard_card.dart';
import 'package:flutter/material.dart';

import '../core/talker_service.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final List<Color?> _currentCardColors = [];
  final List<double> _currentScales = [];
  List<Map<String, String>>? modes;
  List? _rankedModes;
  bool _firstIteration = true;

  late Future<List<Map<String, dynamic>>> dataFuture;

  List<Map<String, dynamic>> data = [];

  List? rankUpdateData;

  @override
  void initState() {
    super.initState();
    dataFuture = getDashboardData();
    _listenToRankUpdates();
  }

  Future<List<Map<String, dynamic>>> getDashboardData() async {
    final dashboardData = await RankService().getDashboardData();
    modes = await RankService().getRankedModes(onlyActive: true);
    _rankedModes = modes!.map((mode) => mode["label"]).toList();

    return dashboardData;
  }

  void _listenToRankUpdates() {
    RankService().rankUpdates.listen(
      (List? data) {
        if (mounted) {
          setState(() {
            rankUpdateData = data;
            dataFuture = getDashboardData();
          });
        }
      },
      onDone: () => talker.info("Rank updates stream closed."),
      onError: (e) => talker.error("Error in rank updates stream: $e"),
    );
    RankService().rankCardIndexUpdates.listen((Map<String, dynamic> data) {
      if (mounted) {
        setState(() {
          final Map<String, dynamic> account = this.data.firstWhere(
              (element) => element["AccountId"] == data["accountId"]);
          account["Index"] = data["index"];
          account["Time"] = data["time"];
        });
      }
    });
  }

  int _getProgressionDifference(Map<String, dynamic> newData) {
    int newProgress1 =
        int.parse((newData['LastProgress'] as String).replaceAll("%", ""));
    return newProgress1;
  }

  void _resetCardState(int index) {
    if (index < _currentCardColors.length) {
      _currentCardColors[index] = Colors.black26;
      _currentScales[index] = 1.0;
      SocketService().addResponse(null);
    }
  }

  void _sortCardList() {
    data.sort((a, b) => (a["Position"] as int).compareTo(b["Position"]));
  }

  void showHomePageEditSheet(
    BuildContext context,
  ) async {
    List<Map<String, dynamic>> deepCopiedData =
        data.map((item) => Map<String, dynamic>.from(item)).toList();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: HomePageEditSheet(
            data: deepCopiedData,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: "edit-btn",
              onPressed: () => showHomePageEditSheet(context),
              label: const Text("Edit"),
              icon: const Icon(Icons.edit),
            ),
            const SizedBox(
              width: 15,
            ),
            FloatingActionButton.extended(
              heroTag: "search-btn",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchScreen()),
                );
              },
              label: const Text("Search"),
              icon: const Icon(Icons.search),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  _firstIteration) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (snapshot.hasData) {
                data = List.from(snapshot.data ?? []);

                _sortCardList();

                return StreamBuilder(
                    stream: SocketService().getStream,
                    builder: (context, socketSnapshot) {
                      Map incomingData = {};
                      String updatedField = "";
                      if (socketSnapshot.data != null) {
                        incomingData = socketSnapshot.data!;
                        updatedField = incomingData.keys
                            .firstWhere((key) => key != "AccountId");
                      }

                      List<Widget> cards = [];

                      for (int i = 0; i < data.length; i++) {
                        var oldItem = Map.from(data[i]);

                        bool hasChanged =
                            incomingData["AccountId"] == oldItem["AccountId"];
                        int progressionDifference = 0;
                        if (hasChanged) {
                          var changedItem = incomingData[updatedField];
                          data[i][updatedField] = changedItem;
                          progressionDifference =
                              _getProgressionDifference(changedItem);
                        }

                        var item = data[i];

                        int index = data[i]["Index"];

                        if (hasChanged) {
                          Color cardColor = Colors.black26;
                          if (progressionDifference > 0) {
                            cardColor = Colors.green.withValues(alpha: 0.75);
                          } else if (progressionDifference < 0) {
                            cardColor = Colors.red.withValues(alpha: 0.75);
                          } else if (progressionDifference == 0) {
                            cardColor = Colors.yellow.withValues(alpha: 0.75);
                          }
                          if (oldItem[updatedField] != null &&
                              oldItem[updatedField]["Rank"] == "Unranked") {
                            cardColor = Colors.blue.withValues(alpha: 0.75);
                          }
                          double cardScale = 1.05;
                          Future.delayed(
                              const Duration(seconds: 1, milliseconds: 250),
                              () {
                            _resetCardState(i);
                          });
                          index = _rankedModes!.indexOf(updatedField);
                          _currentCardColors[i] = cardColor;
                          _currentScales[i] = cardScale;
                        }

                        List rankingKeysList =
                            modes!.map((mode) => mode["key"]).toList();

                        if (rankUpdateData != null &&
                            item["AccountId"] == rankUpdateData![0]) {
                          index = rankingKeysList.indexOf(rankUpdateData![1]);
                        }

                        item["Index"] = index;

                        if (_currentCardColors.length <= i) {
                          _currentCardColors.add(Colors.black26);
                          _currentScales.add(1.0);
                        }

                        if (data[i]["AccountAvatar"] != null) {
                          AvatarManager().setAvatar(
                              item["AccountId"], data[i]["AccountAvatar"]);
                        }

                        data[i]["AccountAvatar"] =
                            AvatarManager().getAvatar(item["AccountId"]);

                        if (!item["Visible"]) {
                          continue;
                        }
                        final String mode = modes![index]["label"]!;
                        if (hasChanged ||
                            (item[mode] != null &&
                                item[mode]['TotalProgress'] !=
                                    item[mode]["AnimationEnd"])) {
                          cards.add(_buildAnimatedCard(item, i, index));
                        } else {
                          cards.add(_buildSimpleCard(
                              item, index, _currentCardColors[i]!, modes!));
                        }
                      }

                      if (cards.isEmpty) {
                        bool hasData = data.isNotEmpty;
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                hasData
                                    ? Icons.visibility_off
                                    : Icons.dashboard_outlined,
                                size: 100,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                hasData
                                    ? 'All cards are currently hidden'
                                    : 'Welcome to your Dashboard',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                hasData
                                    ? 'Toggle visibility to see your data.'
                                    : 'Here’s how you can get started...',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  if (hasData) {
                                    showHomePageEditSheet(context);
                                  } else {
                                    //TODO: Link tutorial video and/or Discord Server for help
                                  }
                                },
                                child:
                                    Text(hasData ? 'Edit Cards' : 'Learn More'),
                              ),
                            ],
                          ),
                        );
                      }

                      _firstIteration = false;

                      return SingleChildScrollView(
                        child: Center(
                          child: Wrap(
                            spacing: 10.0,
                            runSpacing: 10.0,
                            children: cards,
                          ),
                        ),
                      );
                    });
              } else {
                return const Center(child: Text('No data'));
              }
            },
          ),
        ));
  }

  Widget _buildAnimatedCard(dynamic item, int i, int index) {
    return TweenAnimationBuilder<Color?>(
      key: ValueKey(item.toString()),
      tween: ColorTween(begin: Colors.black26, end: _currentCardColors[i]),
      duration: const Duration(milliseconds: 400),
      builder: (context, color, child) {
        return TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: _currentScales[i]),
            duration: const Duration(milliseconds: 100),
            builder: (context, scale, child) {
              final String mode = modes![index]["label"]!;

              if (!(item as Map).containsKey(mode)) {
                return _buildSimpleCard(item, index, color!, modes!);
              }

              double begin = (item[mode]["AnimationStart"] as num).toDouble();
              double end = (item[mode]["AnimationEnd"] as num).toDouble();

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: begin.toDouble(), end: end.toDouble()),
                duration: const Duration(milliseconds: 400),
                builder: (context, progress, child) {
                  final itemCopy = Map<String, dynamic>.from(item);
                  itemCopy[mode] = Map<String, dynamic>.from(item[mode]);
                  itemCopy[mode]['TotalProgress'] = progress;
                  itemCopy[mode]['RankProgression'] = (progress % 100) / 100;
                  return Transform.scale(
                    scale: scale,
                    child: _buildSimpleCard(progress == end ? item : itemCopy,
                        index, color!, modes!),
                  );
                },
              );
            });
      },
    );
  }

  Widget _buildSimpleCard(
      dynamic item, int index, Color color, List<Map<String, String>> modes) {
    return SizedBox(
      width: 375,
      height: 375,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: DashboardCard(
          item: item,
          color: color,
          index: index,
          modes: modes,
        ),
      ),
    );
  }
}
