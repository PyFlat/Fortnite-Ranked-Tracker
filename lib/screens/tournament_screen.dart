import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fortnite_ranked_tracker/core/rank_service.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../components/tournament_info_container.dart';

class TournamentScreen extends StatefulWidget {
  final Talker talker;
  const TournamentScreen({super.key, required this.talker});

  @override
  TournamentScreenState createState() => TournamentScreenState();
}

class TournamentScreenState extends State<TournamentScreen> {
  Timer? refreshTimer;

  Future<List<Map<String, dynamic>>>? _initializationFuture;
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
    sessions = sessions.where((session) {
      DateTime endTime = DateTime.parse(session['endTime']);
      DateTime endTimePlus30Min = endTime.add(Duration(minutes: 30));
      return endTimePlus30Min.isAfter(currentTime);
    }).toList();

    if (sessions.isEmpty) return null;

    DateTime nextSessionStart = sessions
        .map((session) => DateTime.parse(session['beginTime']))
        .reduce((a, b) => a.isBefore(b) ? a : b);

    return nextSessionStart;
  }

  Future<List<Map<String, dynamic>>> _getTournamentInfo() async {
    List<Map<String, dynamic>> tournaments = await RankService().fetchEvents();

    tournaments
        .sort((a, b) => getNextSession(a)!.compareTo(getNextSession(b)!));

    return tournaments;
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
                    child: Wrap(
                        children:
                            snapshot.data!.map((Map<String, dynamic> item) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: TournamentInfoContainer(
                        talker: widget.talker, item: item),
                  );
                }).toList())),
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
