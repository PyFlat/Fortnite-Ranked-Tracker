import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventWindowSheet extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> filteredSessions;
  final List<Map<String, dynamic>> cumulativeSessions;
  final Map<String, dynamic>? nextEventWindow;

  final String? eventId;
  final bool? cumulative;
  const EventWindowSheet(
      {super.key,
      required this.title,
      required this.filteredSessions,
      required this.cumulativeSessions,
      this.nextEventWindow,
      this.eventId,
      this.cumulative});

  @override
  State<EventWindowSheet> createState() => _EventWindowSheetState();
}

class _EventWindowSheetState extends State<EventWindowSheet> {
  @override
  void initState() {
    if (widget.eventId != null && widget.cumulative != null) {
      final eventWindow = widget.cumulative!
          ? widget.filteredSessions
              .firstWhere((element) => element["id"] == widget.eventId)
          : widget.cumulativeSessions
              .firstWhere((element) => element["id"] == widget.eventId);
      Navigator.pop(context,
          [eventWindow, widget.filteredSessions, widget.cumulativeSessions]);
    }
    super.initState();
  }

  bool isCumulative = false;

  @override
  Widget build(BuildContext context) {
    final sessions =
        isCumulative ? widget.cumulativeSessions : widget.filteredSessions;
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  widget.title,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          if (widget.cumulativeSessions.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Normal'),
                  selected: !isCumulative,
                  onSelected: (selected) {
                    if (!selected) return;
                    setState(() {
                      isCumulative = false;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Cumulative'),
                  selected: isCumulative,
                  onSelected: (selected) {
                    if (!selected) return;
                    setState(() {
                      isCumulative = true;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16)
          ],
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: sessions.map((eventWindow) {
                  String timeUntilNext = '';
                  bool isLive = false;
                  bool isNext = false;
                  DateTime now = DateTime.now();
                  DateTime beginTime =
                      DateTime.parse(eventWindow["beginTime"]).toLocal();
                  DateTime endTime =
                      DateTime.parse(eventWindow["endTime"]).toLocal();
                  String eventTimeText =
                      "${DateFormat('EEEE, dd.MM.yyyy').format(beginTime)} - ${DateFormat('EEEE, dd.MM.yyyy').format(endTime)}";
                  if (!isCumulative) {
                    isLive = beginTime.isBefore(now) &&
                        endTime.add(const Duration(minutes: 30)).isAfter(now);
                    isNext = widget.nextEventWindow == eventWindow;

                    eventTimeText =
                        "${DateFormat('HH:mm').format(beginTime)} - ${DateFormat('HH:mm').format(endTime)}";

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
                  }

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 16.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                      trailing: isCumulative
                          ? SizedBox.shrink()
                          : Column(
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
                              eventTimeText,
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
                        Navigator.pop(context, [
                          eventWindow,
                          widget.filteredSessions,
                          widget.cumulativeSessions
                        ]);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
