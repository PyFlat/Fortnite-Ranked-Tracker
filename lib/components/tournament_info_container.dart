import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fortnite_ranked_tracker/constants/constants.dart';
import 'package:fortnite_ranked_tracker/screens/leaderboard_screen.dart';
import 'package:intl/intl.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../core/tournament_service.dart';

class TournamentInfoContainer extends StatefulWidget {
  final Tournament item;
  final Talker talker;

  const TournamentInfoContainer(
      {super.key, required this.talker, required this.item});

  @override
  TournamentInfoContainerState createState() => TournamentInfoContainerState();
}

class TournamentInfoContainerState extends State<TournamentInfoContainer> {
  bool _isHovered = false;

  void _showTemplateSelectionSheet(BuildContext context, String region) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        List<TournamentWindowTemplate> templates = widget.item.regions[region]!;
        DateTime now = DateTime.now();
        TournamentWindowTemplate? nextTemplate;

        for (var template in templates) {
          if (template.beginTime.isAfter(now)) {
            nextTemplate = template;
            break;
          }
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: templates.map((template) {
                bool isLive = template.beginTime.isBefore(now) &&
                    template.endTime.isAfter(now);
                bool isNext = nextTemplate == template;

                String timeUntilNext = '';
                if (isNext && !isLive) {
                  Duration timeDifference = template.beginTime.difference(now);
                  int days = timeDifference.inDays;
                  int hours = timeDifference.inHours % 24;
                  int minutes = timeDifference.inMinutes % 60;

                  if (days > 0) {
                    timeUntilNext =
                        "Live in $days days $hours hours $minutes minutes";
                  } else {
                    if (hours > 0) {
                      timeUntilNext = "Live in $hours hours $minutes minutes";
                    } else {
                      timeUntilNext = "Live in $minutes minutes";
                    }
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
                          'Session ${template.session}${template.round > 0 ? " Round ${template.round}" : ""}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isLive
                                ? Colors.redAccent
                                : isNext
                                    ? Colors.orange
                                    : null,
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
                          DateFormat.EEEE().format(template.beginTime),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          DateFormat('dd.MM.yyyy').format(template.beginTime),
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
                            "${DateFormat('HH:mm').format(template.beginTime)} - "
                            "${DateFormat('HH:mm').format(template.endTime)}",
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
                      Navigator.pop(context, template);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    ).then((selectedTemplate) {
      if (selectedTemplate != null && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LeaderboardScreen(
              talker: widget.talker,
              tournamentWindow: selectedTemplate,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  Image.network(
                    widget.item.posterImageUrl,
                    fit: BoxFit.cover,
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 12, right: 12, bottom: 24),
                      child: Text(
                        widget.item.title,
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
                      left: -1,
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: widget.item.regions.entries
                              .map((MapEntry<String, dynamic> entry) {
                            String region = entry.key;
                            return Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 12, left: 24, right: 24),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    _showTemplateSelectionSheet(
                                        context, region);
                                  },
                                  child:
                                      Text(Constants.regions[region] ?? region),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    )
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
