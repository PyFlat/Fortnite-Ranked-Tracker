import '../constants/constants.dart';
import '../constants/endpoints.dart';
import '../core/api_service.dart';
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

class HomeScreenState extends State<HomeScreen> {
  final DataBase _database = DataBase();
  final RankService _rankService = RankService();
  List<Map<String, dynamic>> _previousData = [];
  final List<Color?> _currentCardColors = [];
  final List<double> _currentScales = [];
  final List _rankedModes = ["Battle Royale", "Zero Build", "Rocket Racing"];
  bool _firstIteration = true;

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
    final accountTypes = {
      "Battle Royale": "br",
      "Zero Build": "zb",
      "Rocket Racing": "rr"
    };
    List<String> accountIds =
        data.map((item) => item['AccountId'] as String).toList();

    String joinedAccountIds = accountIds.join(',');

    Map<String, String> avatarImages =
        await RankService().getAccountAvatarById(joinedAccountIds);

    for (Map<String, dynamic> account in data) {
      for (var entry in accountTypes.entries) {
        String accountType = entry.key;
        String typeCode = entry.value;
        String? avatarURL = avatarImages[account["AccountId"]];
        account["AccountAvatar"] = avatarURL != null
            ? avatarImages[account["AccountId"]]
            : ApiService().addPathParams(
                Endpoints.skinIcon, {"skinId": Constants.defaultSkinId});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SearchScreen()),
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
            var data = snapshot.data ?? [];

            List<Widget> cards = [];

            for (int i = 0; i < data.length; i++) {
              var item = data[i];
              int dataChanged = -1;
              if (_previousData.isNotEmpty) {
                if (i >= _previousData.length) {
                  continue;
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

              cards.add(
                TweenAnimationBuilder<Color?>(
                  key: ValueKey(item.toString()),
                  tween: ColorTween(
                      begin: Colors.transparent, end: _currentCardColors[i]),
                  duration: const Duration(milliseconds: 400),
                  builder: (context, color, child) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: _currentScales[i]),
                      duration: const Duration(milliseconds: 100),
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: SizedBox(
                            width: 350.0,
                            height: 350.0,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: DashboardCard(
                                  item: item, color: color!, index: index),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
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
}
