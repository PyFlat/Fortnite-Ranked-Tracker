import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fortnite_ranked_tracker/components/avatar_dialog.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../core/rank_service.dart';
import '../core/socket_service.dart';
import '../core/rank_data.dart';
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

  final List<RankData> rankModes;

  final Color? color;

  final int? initialIndex;

  const RankCard(
      {this.color = Colors.black26,
      this.initialIndex,
      super.key,
      required this.displayName,
      this.accountId,
      this.nickName,
      this.searchCardKey,
      this.accountAvatar,
      required this.showMenu,
      required this.showSwitches,
      required this.rankModes});

  @override
  RankCardState createState() => RankCardState();
}

class RankCardState extends State<RankCard>
    with SingleTickerProviderStateMixin {
  late List<bool> _trackingStates;

  late Future<List<Map<String, String>>> dataFuture;
  List<Map<String, String>>? modes;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    dataFuture = RankService().getRankedModes(onlyActive: true);
    _trackingStates =
        widget.rankModes.map((rank) => rank.tracking ?? false).toList();
    _currentIndex = widget.initialIndex ?? 0;
  }

  @override
  void didUpdateWidget(covariant RankCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    dataFuture = RankService().getRankedModes(onlyActive: true);

    _currentIndex = widget.initialIndex ?? 0;
  }

  Future<void> _updatePlayerTracking(bool value, String rankingType) async {
    await RankService()
        .setPlayerTracking(rankingType, value, widget.accountId!);
    SocketService().sendDataChanged(data: [widget.accountId!, rankingType]);
    RankService().emitDataRefresh();
  }

  Timer? _debounce;

  Future<void> _updateIndex(int index) async {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () async {
      await RankService().setPlayerIndex(widget.accountId!, index);
      SocketService().sendDataChanged(
          data: [widget.accountId!, RankService().modes[index]["key"]!]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: widget.color,
      elevation: 15,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: FutureBuilder<List<Map<String, String>>>(
          future: dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                modes == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return const Center(
                child: Text("An error occurred while fetching data"),
              );
            }
            if (snapshot.hasData || modes != null) {
              if (snapshot.hasData) {
                modes = snapshot.data;
              }

              final tabNames = modes!.map((mode) => mode['label']!).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      children: [
                        if (widget.accountAvatar != null)
                          GestureDetector(
                            child: CircleAvatar(
                              radius: 25,
                              backgroundImage:
                                  AssetImage(widget.accountAvatar!),
                            ),
                            onDoubleTap: () =>
                                showAvatarDialog(context, widget.accountId!),
                            onLongPress: () =>
                                showAvatarDialog(context, widget.accountId!),
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
                          ),
                        if (!widget.showMenu) _buildShowIcon(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10.0),
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
                                ? tabNames[_currentIndex - 1]
                                : tabNames[tabNames.length - 1],
                            child: IconButton(
                              onPressed: () async {
                                setState(() {
                                  if (_currentIndex <= 0) {
                                    _currentIndex = tabNames.length - 1;
                                  } else {
                                    _currentIndex--;
                                  }
                                });
                                await _updateIndex(_currentIndex);
                              },
                              icon: const Icon(Icons.chevron_left),
                              color: Colors.white,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  tabNames[_currentIndex],
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
                                    tabNames.length,
                                    (index) => AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      width:
                                          _currentIndex == index ? 24.0 : 8.0,
                                      height: 4.0,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4.0),
                                      decoration: BoxDecoration(
                                        color: _currentIndex == index
                                            ? Colors.deepPurple
                                            : Colors.grey,
                                        borderRadius:
                                            BorderRadius.circular(2.0),
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
                            message: _currentIndex + 1 < tabNames.length
                                ? tabNames[_currentIndex + 1]
                                : tabNames[0],
                            child: IconButton(
                              onPressed: () async {
                                setState(() {
                                  if (_currentIndex + 1 >= tabNames.length) {
                                    _currentIndex = 0;
                                  } else {
                                    _currentIndex++;
                                  }
                                });
                                await _updateIndex(_currentIndex);
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
              );
            }
            return const SizedBox.shrink();
          }),
    );
  }

  Widget _buildContentView() {
    return _buildContent(
      widget.rankModes[_currentIndex],
      _trackingStates[_currentIndex],
      RankService().modes[_currentIndex]["label"]!,
      (bool value) async {
        setState(() {
          _trackingStates[_currentIndex] = value;
        });
        await _updatePlayerTracking(
            value, RankService().modes[_currentIndex]["key"]!);
      },
    );
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

    Color? color;

    if (data.lastProgress != null) {
      final lastProgress = int.parse(data.lastProgress!.replaceAll("%", ""));
      if (lastProgress > 0) {
        color = Colors.greenAccent;
      } else if (lastProgress < 0) {
        color = Colors.red.withValues(alpha: 0.75);
      } else if (lastProgress == 0) {
        color = Colors.yellow.withValues(alpha: 0.75);
      }
      if (data.oldRank != null && data.oldRank == "Unranked") {
        color = Colors.blueAccent;
      }
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
                      ? Row(
                          spacing: 4,
                          children: [
                            Text("Last Progress:"),
                            Text(
                              data.lastProgress!,
                              style: TextStyle(color: color),
                            )
                          ],
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
