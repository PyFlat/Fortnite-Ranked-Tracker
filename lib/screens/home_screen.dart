import 'dart:async';

import 'package:fortnite_ranked_tracker/components/home_page_edit_sheet.dart';
import 'package:fortnite_ranked_tracker/core/avatar_manager.dart';
import 'package:fortnite_ranked_tracker/core/socket_service.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../core/rank_service.dart';

import '../components/dashboard_card.dart';
import 'package:flutter/material.dart';

import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  final Talker talker;
  const HomeScreen({super.key, required this.talker});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final RankService _rankService = RankService();
  final List<Color?> _currentCardColors = [];
  final List<double> _currentScales = [];
  final List _rankedModes = [
    "Battle Royale",
    "Zero Build",
    "Rocket Racing",
    "Reload",
    "Reload Zero Build"
  ];
  bool _firstIteration = true;

  late Future<List<Map<String, dynamic>>> dataFuture;

  List<Map<String, dynamic>> data = [];

  List? rankUpdateData;

  @override
  void initState() {
    super.initState();
    dataFuture = _rankService.getDashboardData();
    _listenToRankUpdates();
  }

  void _listenToRankUpdates() {
    _rankService.rankUpdates.listen(
      (List? data) {
        setState(() {
          rankUpdateData = data;
          dataFuture = _rankService.getDashboardData();
        });
      },
      onDone: () => widget.talker.info("Rank updates stream closed."),
      onError: (e) => widget.talker.error("Error in rank updates stream: $e"),
    );
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
                  MaterialPageRoute(
                      builder: (context) => SearchScreen(
                            talker: widget.talker,
                          )),
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

                        int index = 0;

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
                          index = _rankedModes.indexOf(updatedField);
                          _currentCardColors[i] = cardColor;
                          _currentScales[i] = cardScale;
                        }

                        Map<String, int> rankingTypeToIndex = {
                          "battleRoyale": 0,
                          "zeroBuild": 1,
                          "rocketRacing": 2,
                          "reload": 3,
                          "reloadZeroBuild": 4
                        };

                        if (rankUpdateData != null &&
                            item["AccountId"] == rankUpdateData![0]) {
                          index = rankingTypeToIndex[rankUpdateData![1]]!;
                        }

                        if (_currentCardColors.length <= i) {
                          _currentCardColors.add(Colors.black26);
                          _currentScales.add(1.0);
                        }

                        data[i]["AccountAvatar"] =
                            AvatarManager().getAvatar(item["AccountId"]);

                        if (!item["Visible"]) {
                          continue;
                        }

                        cards.add(_buildAnimatedCard(item, i, index));
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
            return Transform.scale(
              scale: scale,
              child: _buildSimpleCard(item, index, color!),
            );
          },
        );
      },
    );
  }

  Widget _buildSimpleCard(dynamic item, int index, Color color) {
    return SizedBox(
      width: 350,
      height: 350,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: DashboardCard(
          item: item,
          color: color,
          index: index,
          talker: widget.talker,
        ),
      ),
    );
  }
}
