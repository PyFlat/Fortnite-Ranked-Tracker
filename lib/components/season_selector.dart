import 'package:flutter/material.dart';

import '../core/season_service.dart';

class SeasonSelector extends StatelessWidget {
  final SeasonService seasonService;
  final String accountId;
  final VoidCallback onSeasonSelected;

  const SeasonSelector({
    super.key,
    required this.seasonService,
    required this.accountId,
    required this.onSeasonSelected,
  });

  void openSeasonBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<List<String>>(
          future: seasonService.fetchSeasons(accountId),
          builder:
              (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No seasons available'));
            } else {
              final seasons = snapshot.data!;
              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Select Season",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: seasons.length,
                      itemBuilder: (context, index) {
                        String season = seasons[index];
                        Map<String, String> season_ =
                            seasonService.formatSeason(season);

                        return ListTile(
                          title: Text(season_["season"]!),
                          subtitle: Text(season_["mode"]!),
                          onTap: () {
                            seasonService.setCurrentSeason(season);
                            onSeasonSelected();
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => openSeasonBottomSheet(context),
      child: const Text("Change Season"),
    );
  }
}
