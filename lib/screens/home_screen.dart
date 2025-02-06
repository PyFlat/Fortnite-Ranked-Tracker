import 'package:fortnite_ranked_tracker/components/home_page_edit_sheet.dart';
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
  final List _rankedModes = modes.map((mode) => mode["label"]).toList();
  bool _firstIteration = true;

  List<Map<String, dynamic>> data = [];

  late Future<List<Map<String, dynamic>>> _future;

  List? rankUpdateData;

  @override
  void initState() {
    super.initState();
    _future = _getData();
    _rankService.rankUpdates.listen((List? data) {
      rankUpdateData = data;
      if (mounted) {
        setState(() {
          _future = _getData();
        });
      }
    });
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
    List<String> accountIds =
        data.map((item) => item['AccountId'] as String).toList();

    String joinedAccountIds = accountIds.join(',');

    if (accountIds.isNotEmpty) {
      avatarImages = await RankService().getAccountAvatarById(joinedAccountIds);
    }

    for (Map<String, dynamic> account in data) {
      for (var mode in modes) {
        String accountType = mode['label']!;
        String typeCode = mode['short']!.toLowerCase();
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
                "RankProgressionText": null,
                "TotalProgress": null
              };
              continue;
            }

            var rankData = result[0];

            int dataProgress = rankData["progress"];

            String lastProgress = calculatePercentageDifference(
                rankData["total_progress"],
                result.length > 1 ? result[1]["total_progress"] : 0,
                rankData["rank"],
                result.length > 1 ? result[1]["rank"] : "Unranked");

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
              "RankProgressionText": progressText,
              "TotalProgress": rankData["total_progress"]
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
            if (oldData.containsKey(rankMode) &&
                oldData[rankMode]["LastProgress"] == null &&
                newData.containsKey(rankMode) &&
                newData[rankMode]["Rank"] != "Unranked") {
              dataChanged = index;
              continue;
            }
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

  void _sortCardList() {
    data.sort((a, b) => a["Position"].compareTo(b["Position"]));
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
          future: _future,
          builder: (context, snapshot) {
            data = snapshot.data ?? [];

            _sortCardList();

            List<Widget> cards = [];

            for (int i = 0; i < data.length; i++) {
              var item = data[i];

              int dataChanged = -1;
              int previousProgress = 0;
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
                  cardColor = Colors.green.withValues(alpha: .75);
                } else if (progressionDifference < 0) {
                  cardColor = Colors.red.withValues(alpha: .75);
                } else if (progressionDifference == 0) {
                  cardColor = Colors.yellow.withValues(alpha: .75);
                }
                cardScale = 1.05;
                Future.delayed(const Duration(seconds: 1, milliseconds: 250),
                    () => _resetCardState(i));
                index = dataChanged;
                previousProgress = _previousData[i][_rankedModes[dataChanged]]
                        ["TotalProgress"] ??
                    0;
                if (previousProgress > 1700) {
                  previousProgress = (1700 +
                          (_previousData[i][_rankedModes[dataChanged]]
                                  ["RankProgression"] *
                              100))
                      .toInt();
                }
              }

              if (rankUpdateData != null &&
                  item["AccountId"] == rankUpdateData![0]) {
                index = rankUpdateData![1];
              }

              if (_currentCardColors.length <= i) {
                _currentCardColors.add(Colors.black26);
                _currentScales.add(1.0);
              }
              _currentCardColors[i] = cardColor;
              _currentScales[i] = cardScale;

              if (item["Visible"] == 0) {
                continue;
              }
              cards.add(_buildAnimatedCard(item, i, index, previousProgress));
            }

            _previousData = List.from(data);

            if (!_firstIteration && cards.isEmpty) {
              bool hasData = data.isNotEmpty;
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasData ? Icons.visibility_off : Icons.dashboard_outlined,
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
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                      child: Text(hasData ? 'Edit Cards' : 'Learn More'),
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
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(
      dynamic item, int i, int index, int previousProgress) {
    return TweenAnimationBuilder<Color?>(
      key: ValueKey(item.toString()),
      tween: ColorTween(begin: Colors.black26, end: _currentCardColors[i]),
      duration: const Duration(milliseconds: 400),
      builder: (context, color, child) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: _currentScales[i]),
          duration: const Duration(milliseconds: 100),
          builder: (context, scale, child) {
            final String mode = modes[index]["label"]!;

            if (!(item as Map).containsKey(mode)) {
              return _buildSimpleCard(item, index, color!);
            }
            double totalProgress =
                ((item[mode]["TotalProgress"] ?? 0) as int).toDouble();

            if (totalProgress > 1700) {
              totalProgress =
                  (1700 + (item[mode]["RankProgression"] * 100)).toDouble();
            }
            double begin = totalProgress - (totalProgress - previousProgress);
            if (previousProgress == 0) {
              begin = totalProgress;
            }
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: begin, end: totalProgress),
              duration: const Duration(milliseconds: 1000),
              builder: (context, progress, child) {
                final itemCopy = Map<String, dynamic>.from(item);
                itemCopy[mode] = Map<String, dynamic>.from(item[mode]);
                itemCopy[mode]['RankProgression'] = (progress % 100) / 100;

                return Transform.scale(
                  scale: scale,
                  child: _buildSimpleCard(
                    progress == totalProgress ? item : itemCopy,
                    index,
                    color!,
                  ),
                );
              },
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
