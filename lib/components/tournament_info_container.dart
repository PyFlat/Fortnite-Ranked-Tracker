import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fortnite_ranked_tracker/constants/constants.dart';
import 'package:fortnite_ranked_tracker/screens/leaderboard_screen.dart';
import 'package:intl/intl.dart';

import 'hoverable_region_item.dart';

class TournamentInfoContainer extends StatefulWidget {
  final Map<String, dynamic> item;

  const TournamentInfoContainer({super.key, required this.item});

  @override
  TournamentInfoContainerState createState() => TournamentInfoContainerState();
}

class TournamentInfoContainerState extends State<TournamentInfoContainer> {
  bool _isHovered = false;
  String? selectedRegion;
  late Timer updateTimer;

  @override
  void initState() {
    super.initState();
    updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Map<String, dynamic>? _getNextEventSession(
      List<Map<String, dynamic>> sessions) {
    DateTime now = DateTime.now();
    Map<String, dynamic>? nextEventWindow;

    sessions.sort((a, b) => DateTime.parse((a["beginTime"]))
        .compareTo(DateTime.parse((b["beginTime"]))));

    for (var session in sessions) {
      if (DateTime.parse(session["beginTime"]).toLocal().isAfter(now) &&
          nextEventWindow == null) {
        nextEventWindow = session;
        break;
      }
    }
    return nextEventWindow;
  }

  Map<String, dynamic>? _getLiveSession(List<Map<String, dynamic>> sessions) {
    Map<String, dynamic>? liveSession;
    for (var eventWindow in sessions) {
      DateTime now = DateTime.now();
      DateTime beginTime = DateTime.parse(eventWindow["beginTime"]).toLocal();
      DateTime endTime = DateTime.parse(eventWindow["endTime"]).toLocal();
      bool isLive = beginTime.isBefore(now) &&
          endTime.add(const Duration(minutes: 30)).isAfter(now);
      if (isLive) {
        liveSession = eventWindow;
      }
    }
    return liveSession;
  }

  void _showTemplateSelectionSheet(BuildContext context, String region) {
    setState(() {
      selectedRegion = region;
    });

    showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).canvasColor,
      builder: (BuildContext context) {
        List<Map<String, dynamic>> filteredSessions =
            (widget.item["windows"][region] as List).cast();

        filteredSessions.sort((a, b) => DateTime.parse(a["beginTime"])
            .compareTo(DateTime.parse(b["beginTime"])));

        Map<String, dynamic>? nextEventWindow =
            _getNextEventSession(filteredSessions);

        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: filteredSessions.map((eventWindow) {
                DateTime now = DateTime.now();
                DateTime beginTime =
                    DateTime.parse(eventWindow["beginTime"]).toLocal();
                DateTime endTime =
                    DateTime.parse(eventWindow["endTime"]).toLocal();
                bool isLive = beginTime.isBefore(now) &&
                    endTime.add(const Duration(minutes: 30)).isAfter(now);
                bool isNext = nextEventWindow == eventWindow;

                String timeUntilNext = '';
                if (isNext && !isLive) {
                  Duration timeDifference = beginTime.difference(now);
                  int days = timeDifference.inDays;
                  int hours = timeDifference.inHours % 24;
                  int minutes = timeDifference.inMinutes % 60;

                  if (days > 0) {
                    timeUntilNext =
                        "Live in $days days $hours hours $minutes minutes";
                  } else if (hours > 0) {
                    timeUntilNext = "Live in $hours hours $minutes minutes";
                  } else {
                    timeUntilNext = "Live in $minutes minutes";
                  }
                }

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 16.0,
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          eventWindow["windowName"],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isLive
                                ? Colors.redAccent
                                : (isNext ? Colors.orange : null),
                          ),
                        ),
                        if (isLive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat.EEEE().format(beginTime),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          DateFormat('dd.MM.yyyy').format(beginTime),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${DateFormat('HH:mm').format(beginTime)} - ${DateFormat('HH:mm').format(endTime)}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          if (isNext && !isLive)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                timeUntilNext,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context, eventWindow);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    ).then((Map<String, dynamic>? selectedTemplate) {
      if (selectedTemplate != null && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LeaderboardScreen(
                tournamentWindow: selectedTemplate,
                metadata: widget.item,
                region: region),
          ),
        );
      }
    });
  }

  String _formatEventTime(DateTime startTime, DateTime endTime,
      {bool isLive = false, shortFormat = false}) {
    final now = DateTime.now();

    if (isLive) {
      return "LIVE NOW";
    }

    final duration = startTime.difference(now);

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (duration.isNegative) {
      return "ENDED";
    }

    if (days > 0) {
      if (shortFormat) {
        return "IN $days DAY${days > 1 ? 'S' : ''}";
      }
      return "IN $days DAY${days > 1 ? 'S' : ''} $hours HRS $minutes MINS";
    } else if (hours > 0) {
      if (shortFormat) {
        return "IN $hours HRS";
      }
      return "IN $hours HRS $minutes MINS";
    } else {
      return "IN $minutes MINS";
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> sessionData =
        ((widget.item["windows"] as Map).values.expand((list) => list).toList())
            .cast();

    Map<String, dynamic>? nextSession = _getLiveSession(sessionData);
    bool isLive = nextSession != null;
    nextSession ??= _getNextEventSession(sessionData);

    String formattedTime = nextSession != null
        ? _formatEventTime(DateTime.parse(nextSession["beginTime"]),
            DateTime.parse(nextSession["endTime"]),
            isLive: isLive)
        : "ENDED";

    bool isEnded = formattedTime.contains("ENDED");

    return GestureDetector(
      onTap: () {
        setState(() {
          if (Platform.isAndroid || Platform.isIOS) {
            _isHovered = !_isHovered;
          }
        });
      },
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            _isHovered = true;
          });
        },
        onExit: (_) {
          setState(() {
            _isHovered = false;
          });
        },
        child: SizedBox(
          width: 275,
          child: AspectRatio(
            aspectRatio: 750 / 1080,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Stack(
                children: [
                  if (widget.item["imageUrl"] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        widget.item["imageUrl"],
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (!_isHovered)
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: FractionallySizedBox(
                          widthFactor: 0.9,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  isLive
                                      ? Colors.red.shade200
                                      : isEnded
                                          ? Colors.grey
                                          : Colors.purpleAccent,
                                  isLive
                                      ? Colors.red
                                      : isEnded
                                          ? Colors.blueGrey
                                          : Colors.purple,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .2),
                                  spreadRadius: 2,
                                  blurRadius: 6,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            child: Text(
                              formattedTime,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 12, right: 12, bottom: 24),
                      child: Text(
                        widget.item["longTitle"],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(2.0, 2.0),
                              blurRadius: 4.0,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_isHovered) ...[
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: .5),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: (Constants.regions.keys.toList())
                              .where((region) =>
                                  widget.item["windows"].containsKey(region))
                              .map((region) {
                            List<Map<String, dynamic>> filteredSessions =
                                (widget.item["windows"][region] as List).cast();

                            Map<String, dynamic>? nextSession =
                                _getLiveSession(filteredSessions);
                            bool isLive = nextSession != null;
                            nextSession ??=
                                _getNextEventSession(filteredSessions);

                            String regionLabel =
                                Constants.regions[region] ?? region;
                            String sessionTime = nextSession != null
                                ? _formatEventTime(
                                    DateTime.parse(nextSession["beginTime"]),
                                    DateTime.parse(nextSession["endTime"]),
                                    isLive: isLive,
                                    shortFormat: true)
                                : "ENDED";

                            bool isSoon = sessionTime.contains("MINS");

                            return HoverableRegionItem(
                              regionLabel: regionLabel,
                              sessionTime: sessionTime,
                              isLive: isLive,
                              isSoon: isSoon,
                              onTap: () {
                                _showTemplateSelectionSheet(context, region);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
