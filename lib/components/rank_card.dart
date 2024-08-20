import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fortnite_ranked_tracker/core/database.dart';
import 'package:fortnite_ranked_tracker/core/rank_service.dart';
import 'package:fortnite_ranked_tracker/screens/database_screen.dart';
import 'package:fortnite_ranked_tracker/screens/graph_screen.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../screens/search_screen.dart';

class RankCard extends StatefulWidget {
  final String displayName;
  final String? accountId;
  final bool showMenu;
  final bool showSwitches;
  final String? accountAvatar;

  final String? battleRoyaleProgressText;
  final double? battleRoyaleProgress;
  final String? battleRoyaleLastProgress;
  final String? battleRoyaleLastChanged;
  final int? battleRoyaleDailyMatches;
  final String? battleRoyaleRankImagePath;
  final String? battleRoyaleRank;
  final bool battleRoyaleActive;
  final bool? battleRoyaleTracking;

  final String? zeroBuildProgressText;
  final double? zeroBuildProgress;
  final String? zeroBuildLastProgress;
  final String? zeroBuildLastChanged;
  final int? zeroBuildDailyMatches;
  final String? zeroBuildRankImagePath;
  final String? zeroBuildRank;
  final bool zeroBuildActive;
  final bool? zeroBuildTracking;

  final String? rocketRacingProgressText;
  final double? rocketRacingProgress;
  final String? rocketRacingLastProgress;
  final String? rocketRacingLastChanged;
  final int? rocketRacingDailyMatches;
  final String? rocketRacingRankImagePath;
  final String? rocketRacingRank;
  final bool rocketRacingActive;
  final bool? rocketRacingTracking;

  final Color? color;

  final int? initialIndex;

  final Talker talker;

  const RankCard(
      {this.color = Colors.black26,
      this.initialIndex = 0,
      super.key,
      required this.displayName,
      this.accountId,
      this.accountAvatar,
      required this.showMenu,
      required this.showSwitches,
      this.battleRoyaleProgressText,
      this.battleRoyaleProgress,
      this.battleRoyaleLastProgress,
      this.battleRoyaleLastChanged,
      this.battleRoyaleDailyMatches,
      this.battleRoyaleRankImagePath,
      this.battleRoyaleRank,
      required this.battleRoyaleActive,
      this.battleRoyaleTracking,
      this.zeroBuildProgressText,
      this.zeroBuildProgress,
      this.zeroBuildLastProgress,
      this.zeroBuildLastChanged,
      this.zeroBuildDailyMatches,
      this.zeroBuildRankImagePath,
      this.zeroBuildRank,
      required this.zeroBuildActive,
      this.zeroBuildTracking,
      this.rocketRacingProgressText,
      this.rocketRacingProgress,
      this.rocketRacingLastProgress,
      this.rocketRacingLastChanged,
      this.rocketRacingDailyMatches,
      this.rocketRacingRankImagePath,
      this.rocketRacingRank,
      required this.rocketRacingActive,
      this.rocketRacingTracking,
      required this.talker});

  @override
  RankCardState createState() => RankCardState();
}

class RankCardState extends State<RankCard>
    with SingleTickerProviderStateMixin {
  late bool _battleRoyaleTracking;
  late bool _zeroBuildTracking;
  late bool _rocketRacingTracking;

  @override
  void initState() {
    super.initState();
    _battleRoyaleTracking = widget.battleRoyaleTracking ?? false;
    _zeroBuildTracking = widget.zeroBuildTracking ?? false;
    _rocketRacingTracking = widget.rocketRacingTracking ?? false;
  }

  Future<void> _updatePlayerTracking(bool value, int key) async {
    await DataBase().updatePlayerTracking(
        value, key, widget.accountId!, widget.displayName);
    RankService().refreshMainPage();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: widget.color,
      elevation: 15,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: DefaultTabController(
        initialIndex: widget.initialIndex!,
        length: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                children: [
                  if (widget.accountAvatar != null)
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: NetworkImage(widget.accountAvatar!),
                    ),
                  const SizedBox(
                    width: 24,
                  ),
                  Expanded(
                    child: Text(
                      widget.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  if (widget.showMenu) _buildMenu()
                ],
              ),
            ),
            const TabBar(
              tabs: [
                Tab(
                  child: Text(
                    "Battle Royale",
                    textAlign: TextAlign.center,
                  ),
                ),
                Tab(
                  child: Text(
                    "Zero Build",
                    textAlign: TextAlign.center,
                  ),
                ),
                Tab(
                  child: Text(
                    "Rocket Racing",
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              indicatorColor: Colors.deepPurple,
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildContent(
                    widget.battleRoyaleProgressText,
                    widget.battleRoyaleProgress,
                    widget.battleRoyaleLastProgress,
                    widget.battleRoyaleLastChanged,
                    widget.battleRoyaleDailyMatches,
                    widget.battleRoyaleRankImagePath,
                    widget.battleRoyaleRank,
                    widget.battleRoyaleActive,
                    _battleRoyaleTracking,
                    "Battle Royale",
                    (bool value) async {
                      setState(() {
                        _battleRoyaleTracking = value;
                      });
                      await _updatePlayerTracking(value, 0);
                    },
                  ),
                  _buildContent(
                    widget.zeroBuildProgressText,
                    widget.zeroBuildProgress,
                    widget.zeroBuildLastProgress,
                    widget.zeroBuildLastChanged,
                    widget.zeroBuildDailyMatches,
                    widget.zeroBuildRankImagePath,
                    widget.zeroBuildRank,
                    widget.zeroBuildActive,
                    _zeroBuildTracking,
                    "Zero Build",
                    (bool value) async {
                      setState(() {
                        _zeroBuildTracking = value;
                      });
                      await _updatePlayerTracking(value, 1);
                    },
                  ),
                  _buildContent(
                    widget.rocketRacingProgressText,
                    widget.rocketRacingProgress,
                    widget.rocketRacingLastProgress,
                    widget.rocketRacingLastChanged,
                    widget.rocketRacingDailyMatches,
                    widget.rocketRacingRankImagePath,
                    widget.rocketRacingRank,
                    widget.rocketRacingActive,
                    _rocketRacingTracking,
                    "Rocket Racing",
                    (bool value) async {
                      setState(() {
                        _rocketRacingTracking = value;
                      });
                      await _updatePlayerTracking(value, 2);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu() {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (String value) {
        if (value == "show_account_details") {
          showCustomDialog(context, widget.displayName, widget.accountId!);
        } else if (value == "open_user") {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => SearchScreen(
                      accountId: widget.accountId,
                      displayName: widget.displayName,
                      talker: widget.talker,
                    )),
          );
        } else if (value == "open_database") {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => DatabaseScreen(account: {
                        "displayName": widget.displayName,
                        "accountId": widget.accountId
                      })));
        } else if (value == "open_graph") {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GraphScreen(
                        account: {
                          "displayName": widget.displayName,
                          "accountId": widget.accountId
                        },
                        talker: widget.talker,
                      )));
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          const PopupMenuItem<String>(
            value: "open_user",
            child: Row(
              children: [
                Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.open_in_new)),
                Text(
                  'Open User',
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: "show_account_details",
            child: Row(
              children: [
                Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.remove_red_eye_rounded)),
                Text(
                  'Show Account Details',
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: "open_database",
            child: Row(
              children: [
                Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.storage_rounded)),
                Text(
                  'Open Database',
                ),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: "open_graph",
            child: Row(
              children: [
                Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.trending_up_rounded)),
                Text(
                  'Open Graph',
                ),
              ],
            ),
          ),
        ];
      },
    );
  }

  Color _getProgressColor(double progress) {
    double hue = (1 - progress) * 0 + progress * 120;

    Color color = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();

    return color;
  }

  Widget _buildContent(
      String? progressText,
      double? progress,
      String? lastProgress,
      String? lastChanged,
      int? dailyMatches,
      String? rankImagePath,
      String? rank,
      bool active,
      bool? tracking,
      String category,
      Future<void> Function(bool) onTrackingChanged) {
    if (!active) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Tracking for `$category` is not active!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 15),
          FilledButton.icon(
              onPressed: () {
                onTrackingChanged(true);
              },
              icon: const Icon(Icons.check),
              label: const Text("Activate"))
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (progress != null)
              CircularPercentIndicator(
                radius: 50,
                lineWidth: 6,
                percent: progress,
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: _getProgressColor(progress).withOpacity(0.75),
                backgroundColor: Colors.transparent,
                header: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    lastChanged ?? "",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
                footer: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: (lastProgress != null)
                      ? Text(
                          "Last Progress: $lastProgress",
                        )
                      : const SizedBox.shrink(),
                ),
                center: Text(
                  progressText ?? "",
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (dailyMatches != null) Text("Daily Matches: $dailyMatches"),
                const SizedBox(
                  height: 15,
                ),
                if (rankImagePath != null)
                  Image.asset(
                    rankImagePath,
                    width: 75,
                    height: 75,
                  ),
                const SizedBox(
                  height: 15,
                ),
                Text(
                  rank ?? "No Rank",
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (widget.showSwitches) _buildSwitches(tracking!, onTrackingChanged)
      ],
    );
  }

  Widget _buildSwitches(bool tracking, Function trackingChanged) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Tracking:",
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(
            width: 16,
          ),
          Switch(
            value: tracking,
            onChanged: (bool value) {
              trackingChanged(value);
            },
          ),
        ],
      ),
    );
  }
}

class CustomDialog extends StatefulWidget {
  final String accountName;
  final String accountId;

  const CustomDialog(
      {super.key, required this.accountName, required this.accountId});

  @override
  State<CustomDialog> createState() => _CustomDialogState();
}

class _CustomDialogState extends State<CustomDialog> {
  late TextEditingController _nameController;
  late TextEditingController _idController;
  bool _showCheckmarkName = false;
  bool _showCheckmarkId = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.accountName);
    _idController = TextEditingController(text: widget.accountId);
  }

  void _copyToClipboard(String text, String type) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() {
      if (type == 'name') {
        _showCheckmarkName = true;
        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            _showCheckmarkName = false;
          });
        });
      } else if (type == 'id') {
        _showCheckmarkId = true;
        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            _showCheckmarkId = false;
          });
        });
      }
    });
  }

  OutlineInputBorder _getInputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(
        color: Colors.deepPurple.shade400,
        width: 1.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(16.0),
      titlePadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      title: const Text(
        'Account Details',
        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display Name Text Field
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  children: [
                    TextField(
                      readOnly: true,
                      controller: _nameController,
                      enableInteractiveSelection: false,
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        labelText: "Display Name",
                        enabledBorder: _getInputBorder(),
                        border: _getInputBorder(),
                        focusedBorder: _getInputBorder(),
                        suffixIcon: _showCheckmarkName
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () {
                                  _copyToClipboard(widget.accountName, 'name');
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          // Account Id Text Field
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  children: [
                    TextField(
                      readOnly: true,
                      controller: _idController,
                      enableInteractiveSelection: false,
                      textAlign: TextAlign.center,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        labelText: "Account Id",
                        enabledBorder: _getInputBorder(),
                        border: _getInputBorder(),
                        focusedBorder: _getInputBorder(),
                        suffixIcon: _showCheckmarkId
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () {
                                  _copyToClipboard(widget.accountId, 'id');
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}

void showCustomDialog(
    BuildContext context, String accountName, String accountId) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return CustomDialog(
        accountName: accountName,
        accountId: accountId,
      );
    },
  );
}
