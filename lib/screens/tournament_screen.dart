import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fortnite_ranked_tracker/core/rank_service.dart';
import '../components/tournament_info_container.dart';

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  TournamentScreenState createState() => TournamentScreenState();
}

class TournamentScreenState extends State<TournamentScreen> {
  Timer? refreshTimer;

  Future<Map<String, List<Map<String, dynamic>>>>? _initializationFuture;
  @override
  void initState() {
    super.initState();

    _initializationFuture = _getTournamentInfo();
  }

  DateTime? getNextSession(Map<String, dynamic> tournament) {
    List<Map<String, dynamic>> sessions = [];
    Map<String, dynamic> windows = tournament['windows'];

    for (var regionSessions in windows.values) {
      sessions.addAll((regionSessions as List).cast<Map<String, dynamic>>());
    }

    DateTime currentTime = DateTime.now().toUtc();

    List<Map<String, dynamic>> upcomingSessions = [];
    List<Map<String, dynamic>> endedSessions = [];

    for (var session in sessions) {
      DateTime endTime = DateTime.parse(session['endTime']);

      if (endTime.add(Duration(minutes: 30)).isAfter(currentTime)) {
        upcomingSessions.add(session);
      } else {
        endedSessions.add(session);
      }
    }

    if (upcomingSessions.isNotEmpty) {
      DateTime nextSessionStart = upcomingSessions
          .map((session) => DateTime.parse(session['beginTime']))
          .reduce((a, b) => a.isBefore(b) ? a : b);
      return nextSessionStart;
    }

    if (endedSessions.isNotEmpty) {
      DateTime lastEndedSessionEnd = endedSessions
          .map((session) => DateTime.parse(session['endTime']))
          .reduce((a, b) => a.isAfter(b) ? a : b);
      return lastEndedSessionEnd;
    }

    return null;
  }

  Future<Map<String, List<Map<String, dynamic>>>> _getTournamentInfo() async {
    List<Map<String, dynamic>> tournaments = await RankService().fetchEvents();

    List<Map<String, dynamic>> tournamentsHistory =
        await RankService().fetchEventsHistory(days: 200);

    tournaments
        .sort((a, b) => getNextSession(a)!.compareTo(getNextSession(b)!));

    tournamentsHistory
        .sort((a, b) => getNextSession(b)!.compareTo(getNextSession(a)!));

    return {
      "tournaments": tournaments,
      "tournamentsHistory": tournamentsHistory
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _initializationFuture = _getTournamentInfo();
          });
        },
        label: Text("Refresh"),
        icon: Icon(Icons.refresh_rounded),
      ),
      body: FutureBuilder(
          future: _initializationFuture,
          builder: (builder, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            } else if (snapshot.hasData) {
              return Center(
                child: SingleChildScrollView(
                    child: Column(
                  children: [
                    Wrap(
                        children: (snapshot.data!["tournaments"])!
                            .map((Map<String, dynamic> item) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: TournamentInfoContainer(item: item),
                      );
                    }).toList()),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Divider(
                        thickness: 2,
                      ),
                    ),
                    Wrap(
                        children: (snapshot.data!["tournamentsHistory"])!
                            .map((Map<String, dynamic> item) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: TournamentInfoContainer(item: item),
                      );
                    }).toList()),
                  ],
                )),
              );
            } else {
              return SizedBox.shrink();
            }
          }),
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }
}
