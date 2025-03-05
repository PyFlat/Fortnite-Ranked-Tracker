import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fortnite_ranked_tracker/components/event_window_sheet.dart';
import 'package:fortnite_ranked_tracker/constants/constants.dart';
import 'package:fortnite_ranked_tracker/constants/endpoints.dart';
import 'package:fortnite_ranked_tracker/screens/leaderboard_screen.dart';

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
      if (eventWindow["cumulative"] != null) {
        continue;
      }
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

  List calculateSessions(String region) {
    List<Map<String, dynamic>> filteredSessions =
        List<Map<String, dynamic>>.from((widget.item["windows"][region] as List)
            .map((item) => Map<String, dynamic>.from(item)));

    final cumulativeSessions =
        filteredSessions.where((item) => item["cumulative"] != null).toList();

    filteredSessions.removeWhere((item) => cumulativeSessions.contains(item));

    for (var item in cumulativeSessions) {
      final cumulativeList = item["cumulative"];

      String? latestId;
      DateTime latestEndTime = DateTime(0001);

      for (var id in cumulativeList) {
        final element =
            filteredSessions.firstWhere((element) => element["id"] == id);

        if (element["endTime"] != null) {
          final endTime = DateTime.parse(element["endTime"]);
          if (endTime.isAfter(latestEndTime)) {
            latestEndTime = endTime;
            latestId = id;
          }
        }
      }

      if (latestId != null) {
        final elementToUpdate =
            filteredSessions.firstWhere((element) => element["id"] == latestId);

        elementToUpdate["cumulative"] = item["id"];
      }

      item["cumulative"] = latestId;
    }

    filteredSessions.sort((a, b) => DateTime.parse(a["beginTime"])
        .compareTo(DateTime.parse(b["beginTime"])));

    cumulativeSessions.sort((a, b) => DateTime.parse(a["beginTime"])
        .compareTo(DateTime.parse(b["beginTime"])));

    Map<String, dynamic>? nextEventWindow =
        _getNextEventSession(filteredSessions);

    return [filteredSessions, cumulativeSessions, nextEventWindow];
  }

  Future<List?> _showBottomSheet(
      BuildContext context,
      String region,
      List<Map<String, dynamic>> filteredSessions,
      List<Map<String, dynamic>> cumulativeSessions,
      Map<String, dynamic>? nextEventWindow) async {
    final data = await showModalBottomSheet<List>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).canvasColor,
      builder: (BuildContext context) {
        return EventWindowSheet(
          title: "${widget.item["longTitle"]} - ${Constants.regions[region]}",
          filteredSessions: filteredSessions,
          cumulativeSessions: cumulativeSessions,
          nextEventWindow: nextEventWindow,
        );
      },
    );

    return data;
  }

  Future<void> _showTemplateSelectionSheet(BuildContext context, String region,
      {String? eventId, bool? cumulative}) async {
    setState(() {
      selectedRegion = region;
    });

    bool openCumulative = eventId != null && cumulative != null;

    List sessionData = calculateSessions(region);

    List? data;

    if (!openCumulative) {
      data = await _showBottomSheet(
          context, region, sessionData[0], sessionData[1], sessionData[2]);
      if (data == null) return;
    }

    if (context.mounted) {
      Map<String, dynamic>? eventWindow;

      if (openCumulative) {
        eventWindow = cumulative
            ? (sessionData[0] as List)
                .firstWhere((element) => element["id"] == eventId)
            : (sessionData[1] as List)
                .firstWhere((element) => element["id"] == eventId);
      }

      final value = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LeaderboardScreen(
            tournamentWindow: openCumulative ? eventWindow : data![0],
            filteredSessions: sessionData[0],
            cumulativeSessions: sessionData[1],
            metadata: widget.item,
            region: region,
          ),
        ),
      );

      if (value != null && context.mounted) {
        if (!value[0]) {
          _showTemplateSelectionSheet(
            context,
            region,
            eventId: value[1],
            cumulative: value[2],
          );
        } else {
          _showTemplateSelectionSheet(context, region);
        }
      }
    }
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
                        "${Endpoints.baseUrl}/image-proxy?url=${widget.item["imageUrl"]}",
                        fit: BoxFit.cover,
                        width: 275,
                        height: 275 * (1080 / 750),
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (BuildContext context, Object error,
                            StackTrace? stackTrace) {
                          return const Center(
                            child: Icon(Icons.error, color: Colors.red),
                          );
                        },
                      ),
                    ),
                  if (widget.item["imageUrl"] != null &&
                      (widget.item["imageUrl"] as String).contains("800x800"))
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 7),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
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
