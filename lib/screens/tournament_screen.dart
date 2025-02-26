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
  List<Map<String, dynamic>> tournaments = [];
  List<Map<String, dynamic>> tournamentsHistory = [];
  Future<void>? _loadingFuture;

  @override
  void initState() {
    super.initState();
    _loadingFuture = _getTournamentInfo();

    refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        if (timer.tick % 30 == 0) {
          _loadingFuture = _getTournamentInfo();
        } else {
          _resortTournaments();
        }
        setState(() {});
      }
    });
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

      if (endTime.add(const Duration(minutes: 30)).isAfter(currentTime)) {
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

  Future<void> _getTournamentInfo() async {
    final fetchedTournaments = await RankService().fetchEvents();
    final fetchedTournamentsHistory =
        await RankService().fetchEventsHistory(days: 100);

    fetchedTournaments
        .sort((a, b) => getNextSession(a)!.compareTo(getNextSession(b)!));

    fetchedTournamentsHistory
        .sort((a, b) => getNextSession(b)!.compareTo(getNextSession(a)!));

    setState(() {
      tournaments = fetchedTournaments;
      tournamentsHistory = fetchedTournamentsHistory;
    });
  }

  void _resortTournaments() {
    tournaments
        .sort((a, b) => getNextSession(a)!.compareTo(getNextSession(b)!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _loadingFuture = _getTournamentInfo();
          });
        },
        label: const Text("Refresh"),
        icon: const Icon(Icons.refresh_rounded),
      ),
      body: FutureBuilder(
        future: _loadingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              tournaments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          } else {
            return Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(
                        tournaments.length,
                        (index) =>
                            TournamentInfoContainer(item: tournaments[index]),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Divider(thickness: 2),
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(
                        tournamentsHistory.length,
                        (index) => TournamentInfoContainer(
                            item: tournamentsHistory[index]),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }
}
