import 'package:talker_flutter/talker_flutter.dart';

import '../core/rank_service.dart';
import '../core/utils.dart';

import '../components/dashboard_card.dart';
import '../core/database.dart';
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
  final DataBase _database = DataBase();
  final RankService _rankService = RankService();
  List<Map<String, dynamic>> _previousData = [];
  final List<Color?> _currentCardColors = [];
  final List<double> _currentScales = [];
  final List _rankedModes = ["Battle Royale", "Zero Build", "Rocket Racing"];
  bool _firstIteration = true;
  bool _draggingEnabled = false;
  int _dragged = -1;
  int _target = -1;
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;

  var data = [];

  List<String> _cardPositions = [];

  @override
  void initState() {
    super.initState();
    _rankService.rankUpdates.listen((_) {
      if (mounted) {
        setState(() {
          _getData();
        });
      }
    });
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: -0.025, end: 0.025).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String calculatePercentageDifference(int currentProgress,
      int previousProgress, String currentRank, String previousRank) {
    String percentageDifference = "-";
    if (currentRank == "Unreal") {
      if (previousRank != "Champion") {
        percentageDifference = (previousProgress - currentProgress).toString();
      } else {
        percentageDifference = "${1700 - previousProgress}%";
      }
    } else {
      percentageDifference = "${currentProgress - previousProgress}%";
    }

    return percentageDifference;
  }

  Future<List<Map<String, dynamic>>> _getData() async {
    List<Map<String, dynamic>> data = await _database.getAccountDataActive();
    Map<String, String> avatarImages = {};
    final accountTypes = {
      "Battle Royale": "br",
      "Zero Build": "zb",
      "Rocket Racing": "rr"
    };
    List<String> accountIds =
        data.map((item) => item['AccountId'] as String).toList();

    String joinedAccountIds = accountIds.join(',');

    if (accountIds.isNotEmpty) {
      avatarImages = await RankService().getAccountAvatarById(joinedAccountIds);
    }

    for (Map<String, dynamic> account in data) {
      for (var entry in accountTypes.entries) {
        String accountType = entry.key;
        String typeCode = entry.value;
        account["AccountAvatar"] = avatarImages[account["AccountId"]];

        if (account.containsKey(accountType)) {
          try {
            List result = await _rankService.getRankedDataByAccountId(
                account["AccountId"], typeCode);

            if (result.isEmpty) {
              account[accountType] = {
                "DailyMatches": null,
                "LastProgress": null,
                "LastChanged": null,
                "Rank": "Unranked",
                "RankProgression": null,
                "RankProgressionText": null
              };
              continue;
            }

            var rankData = result[0];

            int dataProgress = rankData["progress"];
            String lastProgress = "-";

            if (result.length > 1) {
              lastProgress = calculatePercentageDifference(
                  rankData["total_progress"],
                  result[1]["total_progress"],
                  rankData["rank"],
                  result[1]["rank"]);
            }

            double progress = rankData["rank"] != "Unreal"
                ? dataProgress / 100
                : convertProgressForUnreal(dataProgress.toDouble());

            String progressText = rankData["rank"] == "Unreal"
                ? '#$dataProgress'
                : "$dataProgress%";

            int dailyMatches;
            DateTime rankDatetime = DateTime.parse(rankData["datetime"]);

            DateTime now = DateTime.now();

            DateTime rankDate = DateTime(
                rankDatetime.year, rankDatetime.month, rankDatetime.day);
            DateTime today = DateTime(now.year, now.month, now.day);

            if (rankDate == today) {
              dailyMatches = rankData["daily_match_id"];
            } else {
              dailyMatches = 0;
            }

            account[accountType] = {
              "DailyMatches": dailyMatches,
              "LastProgress": lastProgress,
              "LastChanged": formatDateTime(rankData["datetime"]),
              "Rank": rankData["rank"],
              "RankProgression": progress,
              "RankProgressionText": progressText
            };
          } catch (e) {
            widget.talker.error(
                "Error updating $accountType for account ${account['AccountId']}: $e");
          }
        }
      }
    }
    return data;
  }

  int _hasDataChanged(
      Map<String, dynamic> newData, Map<String, dynamic> oldData) {
    int dataChanged = -1;
    if (newData["DisplayName"] != oldData["DisplayName"]) {
      return -1;
    }
    bool dataChangedBool = newData.toString() != oldData.toString();
    if (dataChangedBool) {
      for (final (index, rankMode) in _rankedModes.indexed) {
        if (newData[rankMode].toString() != oldData[rankMode].toString()) {
          if (!newData.containsKey(rankMode) ||
              newData[rankMode]["DailyMatches"] == 0 ||
              newData[rankMode]["LastProgress"] == "-" ||
              newData[rankMode]["LastProgress"] == null) {
            dataChanged = -1;
          } else {
            dataChanged = index;
          }
        }
      }
    }
    return dataChanged;
  }

  int _getProgressionDifference(
      Map<String, dynamic> newData, Map<String, dynamic> oldData, String key) {
    int newProgress1 =
        int.parse((newData[key]['LastProgress'] as String).replaceAll("%", ""));
    return newProgress1;
  }

  void _resetCardState(int index) {
    if (index < _currentCardColors.length) {
      setState(() {
        _currentCardColors[index] = Colors.white;
        _currentScales[index] = 1.0;
      });
    }
  }

  List<dynamic> _sortCards(List<dynamic> data) {
    if (data.isEmpty) {
      return data;
    }

    List<String> temp = [];
    data.sort((a, b) => a['Position']!.compareTo(b['Position']!));
    for (Map map in data) {
      temp.add(map['AccountId']);
    }

    if (_cardPositions.isEmpty || _cardPositions.length != data.length) {
      _cardPositions = temp;
    }
    data = _sortCardList(data);

    return data;
  }

  List<dynamic> _sortCardList(List<dynamic> listToSort) {
    listToSort.sort((a, b) {
      int indexA = _cardPositions.indexOf(a["AccountId"]);
      int indexB = _cardPositions.indexOf(b["AccountId"]);
      return indexA.compareTo(indexB);
    });
    return listToSort;
  }

  void _onIconClicked(String accountId, bool visibility) async {
    await _database.setAccountVisibility(accountId, !visibility);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _getData(),
          builder: (context, snapshot) {
            data = snapshot.data ?? [];

            data = _sortCards(data);

            List<Widget> cards = [];

            for (int i = 0; i < data.length; i++) {
              var item = data[i];

              int dataChanged = -1;
              if (_previousData.isNotEmpty) {
                if (i >= _previousData.length) {
                  dataChanged = -1;
                } else {
                  dataChanged = _hasDataChanged(item, _previousData[i]);
                }
              }

              bool hasChanged = dataChanged >= 0;

              int progressionDifference = hasChanged
                  ? _getProgressionDifference(
                      item, _previousData[i], _rankedModes[dataChanged])
                  : 0;
              Color cardColor = Colors.black26;
              double cardScale = 1.0;
              int index = 0;

              if (hasChanged) {
                if (progressionDifference > 0) {
                  cardColor = Colors.green.withOpacity(0.75);
                } else if (progressionDifference < 0) {
                  cardColor = Colors.red.withOpacity(0.75);
                } else if (progressionDifference == 0) {
                  cardColor = Colors.yellow.withOpacity(0.75);
                }
                cardScale = 1.05;
                Future.delayed(const Duration(seconds: 1, milliseconds: 250),
                    () => _resetCardState(i));
                index = dataChanged;
              }

              if (_currentCardColors.length <= i) {
                _currentCardColors.add(Colors.black26);
                _currentScales.add(1.0);
              }
              _currentCardColors[i] = cardColor;
              _currentScales[i] = cardScale;

              if (item["Visible"] == 0 && !_draggingEnabled) {
                continue;
              }

              cards.add(GestureDetector(
                onLongPress: () {
                  if (_shakeAnimation.isAnimating) {
                    _controller.reset();
                    setState(() {
                      _draggingEnabled = false;
                    });
                  } else {
                    _controller.repeat(reverse: true);
                    setState(() {
                      _draggingEnabled = true;
                    });
                  }
                },
                child: AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    if (_shakeAnimation.isAnimating) {
                      return Transform.rotate(
                        angle: _shakeAnimation.value,
                        child: child,
                      );
                    }
                    return Transform.rotate(
                      angle: 0,
                      child: child,
                    );
                  },
                  child: DragTarget<int>(
                    onAcceptWithDetails: (details) async {
                      setState(() {
                        var temp = _cardPositions[details.data];
                        _cardPositions[details.data] = _cardPositions[i];
                        _cardPositions[i] = temp;
                      });
                      await _database.swapCardPositions(details.data, i);
                    },
                    onWillAcceptWithDetails: (details) {
                      setState(() {
                        _target = i;
                      });
                      return true;
                    },
                    onLeave: (data) {
                      setState(() {
                        _target = _dragged;
                      });
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Draggable<int>(
                          ignoringFeedbackSemantics: false,
                          data: i,
                          maxSimultaneousDrags: _draggingEnabled ? 1 : 0,
                          onDragStarted: () {
                            setState(() {
                              _dragged = i;
                            });
                          },
                          onDragEnd: (details) {
                            setState(() {
                              _dragged = -1;
                            });
                          },
                          feedback:
                              _buildSimpleCard(item, index, Colors.white54),
                          child: buildCard(
                              candidateData, i, index, cardColor, item));
                    },
                  ),
                ),
              ));
            }

            _previousData = List.from(data);

            if (!_firstIteration && cards.isEmpty) {
              return const Center(
                child: Text(
                  "No data available. Search for a user and start tracking to populate the dashboard.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
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
          },
        ),
      ),
    );
  }

  Widget buildCard(
      List candidateData, int i, int index, Color cardColor, Map item) {
    Color disabledColor = Colors.red.withOpacity(0.1);
    if (candidateData.isEmpty) {
      if (_dragged == i) {
        return _buildSimpleCard(data[_target], index,
            data[_target]["Visible"] == 1 ? cardColor : disabledColor);
      } else {
        if (item["Visible"] == 1) {
          return _buildAnimatedCard(item, i, index);
        } else {
          return _buildSimpleCard(item, index, disabledColor);
        }
      }
    } else {
      return _buildSimpleCard(data[_dragged], index,
          data[_dragged]["Visible"] == 1 ? cardColor : disabledColor);
    }
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
          iconVisible: _draggingEnabled ? true : false,
          iconState: item["Visible"] == 0 ? false : true,
          onIconClicked: () {
            _onIconClicked(
                item["AccountId"], item["Visible"] == 0 ? false : true);
          },
          color: color,
          index: index,
          talker: widget.talker,
        ),
      ),
    );
  }
}
