import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../core/database.dart';
import '../core/rank_data.dart';
import '../core/rank_service.dart';
import 'account_details_dialog.dart';
import 'user_popup_menu.dart';

class RankCard extends StatefulWidget {
  final String displayName;
  final String? accountId;
  final String? nickName;
  final GlobalKey? searchCardKey;
  final bool showMenu;
  final bool showSwitches;
  final String? accountAvatar;

  final RankData battleRoyale;
  final RankData zeroBuild;
  final RankData rocketRacing;
  final RankData reload;
  final RankData reloadZeroBuild;
  final RankData ballistics;

  final Color? color;

  final int? initialIndex;

  final Talker talker;

  const RankCard(
      {this.color = Colors.black26,
      this.initialIndex = 0,
      super.key,
      required this.displayName,
      this.accountId,
      this.nickName,
      this.searchCardKey,
      this.accountAvatar,
      required this.showMenu,
      required this.showSwitches,
      required this.battleRoyale,
      required this.zeroBuild,
      required this.rocketRacing,
      required this.reload,
      required this.reloadZeroBuild,
      required this.ballistics,
      required this.talker});

  @override
  RankCardState createState() => RankCardState();
}

class RankCardState extends State<RankCard>
    with SingleTickerProviderStateMixin {
  late bool _battleRoyaleTracking;
  late bool _zeroBuildTracking;
  late bool _rocketRacingTracking;
  late bool _reloadTracking;
  late bool _reloadZeroBuildTracking;
  late bool _ballisticsTracking;

  int _currentIndex = 0;
  final List<String> _tabNames = [
    "Battle Royale",
    "Zero Build",
    "Rocket Racing",
    "Reload",
    "Reload Zero Build",
    "Ballistics"
  ];

  @override
  void initState() {
    super.initState();
    _battleRoyaleTracking = widget.battleRoyale.tracking ?? false;
    _zeroBuildTracking = widget.zeroBuild.tracking ?? false;
    _rocketRacingTracking = widget.rocketRacing.tracking ?? false;
    _reloadTracking = widget.reload.tracking ?? false;
    _reloadZeroBuildTracking = widget.reloadZeroBuild.tracking ?? false;
    _ballisticsTracking = widget.ballistics.tracking ?? false;
    _currentIndex = widget.initialIndex ?? 0;
  }

  Future<void> _updatePlayerTracking(bool value, int key) async {
    await DataBase().updatePlayerTracking(
        value, key, widget.accountId!, widget.displayName);
    RankService().emitDataRefresh(data: [widget.accountId!, key]);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: widget.color,
      elevation: 15,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
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
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.nickName == null
                            ? widget.displayName
                            : widget.nickName!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      if (widget.nickName != null)
                        Text(
                          widget.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.showMenu)
                  UserPopupMenu(
                    context: context,
                    displayName: widget.displayName,
                    accountId: widget.accountId!,
                    nickName: widget.nickName,
                    talker: widget.talker,
                  ),
                if (!widget.showMenu) _buildShowIcon(),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .9),
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: .3),
                    spreadRadius: 4,
                    blurRadius: 7.5,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: _currentIndex > 0
                        ? _tabNames[_currentIndex - 1]
                        : _tabNames[_tabNames.length - 1],
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          if (_currentIndex <= 0) {
                            _currentIndex = _tabNames.length - 1;
                          } else {
                            _currentIndex--;
                          }
                        });
                      },
                      icon: const Icon(Icons.chevron_left),
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _tabNames[_currentIndex],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _tabNames.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: _currentIndex == index ? 24.0 : 8.0,
                              height: 4.0,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              decoration: BoxDecoration(
                                color: _currentIndex == index
                                    ? Colors.deepPurple
                                    : Colors.grey,
                                borderRadius: BorderRadius.circular(2.0),
                                boxShadow: _currentIndex == index
                                    ? [
                                        BoxShadow(
                                            color: Colors.deepPurple
                                                .withValues(alpha: .5),
                                            blurRadius: 6.0)
                                      ]
                                    : [],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        )
                      ],
                    ),
                  ),
                  Tooltip(
                    message: _currentIndex + 1 < _tabNames.length
                        ? _tabNames[_currentIndex + 1]
                        : _tabNames[0],
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          if (_currentIndex + 1 >= _tabNames.length) {
                            _currentIndex = 0;
                          } else {
                            _currentIndex++;
                          }
                        });
                      },
                      icon: const Icon(Icons.chevron_right),
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(
            color: Colors.white,
          ),
          Expanded(
            child: _buildContentView(),
          ),
        ],
      ),
    );
  }

  Widget _buildContentView() {
    switch (_currentIndex) {
      case 0:
        return _buildContent(
          widget.battleRoyale,
          _battleRoyaleTracking,
          "Battle Royale",
          (bool value) async {
            setState(() {
              _battleRoyaleTracking = value;
            });
            await _updatePlayerTracking(value, 0);
          },
        );
      case 1:
        return _buildContent(
          widget.zeroBuild,
          _zeroBuildTracking,
          "Zero Build",
          (bool value) async {
            setState(() {
              _zeroBuildTracking = value;
            });
            await _updatePlayerTracking(value, 1);
          },
        );
      case 2:
        return _buildContent(
          widget.rocketRacing,
          _rocketRacingTracking,
          "Rocket Racing",
          (bool value) async {
            setState(() {
              _rocketRacingTracking = value;
            });
            await _updatePlayerTracking(value, 2);
          },
        );
      case 3:
        return _buildContent(
          widget.reload,
          _reloadTracking,
          "Reload",
          (bool value) async {
            setState(() {
              _reloadTracking = value;
            });
            await _updatePlayerTracking(value, 3);
          },
        );
      case 4:
        return _buildContent(
          widget.reloadZeroBuild,
          _reloadZeroBuildTracking,
          "Reload Zero Build",
          (bool value) async {
            setState(() {
              _reloadZeroBuildTracking = value;
            });
            await _updatePlayerTracking(value, 4);
          },
        );
      case 5:
        return _buildContent(
          widget.ballistics,
          _ballisticsTracking,
          "Ballistics",
          (bool value) async {
            setState(() {
              _ballisticsTracking = value;
            });
            await _updatePlayerTracking(value, 5);
          },
        );
      default:
        return const Center(child: Text("Invalid Index"));
    }
  }

  Widget _buildShowIcon() {
    return IconButton(
      onPressed: () {
        showAccountDetailsDialog(
            context, widget.displayName, widget.accountId!, widget.nickName,
            searchCardKey: widget.searchCardKey);
      },
      icon: const Icon(Icons.visibility),
      tooltip: "Show Account Details",
    );
  }

  Color _getProgressColor(double progress) {
    double hue = (1 - progress) * 0 + progress * 120;

    Color color = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();

    return color;
  }

  Widget _buildContent(RankData data, bool? tracking, String category,
      Future<void> Function(bool) onTrackingChanged) {
    if (!data.active) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text(
              'Tracking for `$category` is not active!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
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
            if (data.progress != null)
              CircularPercentIndicator(
                radius: 50,
                lineWidth: 6,
                percent: data.progress!,
                circularStrokeCap: CircularStrokeCap.round,
                progressColor:
                    _getProgressColor(data.progress!).withValues(alpha: .75),
                backgroundColor: Colors.transparent,
                header: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    data.lastChanged ?? "",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
                footer: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: (data.lastProgress != null)
                      ? Text(
                          "Last Progress: ${data.lastProgress}",
                        )
                      : const SizedBox.shrink(),
                ),
                center: Text(
                  data.progressText ?? "",
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (data.dailyMatches != null)
                  Text("Daily Matches: ${data.dailyMatches}"),
                const SizedBox(
                  height: 15,
                ),
                if (data.rankImagePath != null)
                  Image.asset(
                    data.rankImagePath!,
                    width: 75,
                    height: 75,
                  ),
                const SizedBox(
                  height: 15,
                ),
                Text(
                  data.rank ?? "No Rank",
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
