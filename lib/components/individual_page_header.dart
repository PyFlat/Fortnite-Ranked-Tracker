import 'package:flutter/material.dart';

import '../core/season_service.dart';
import '../core/utils.dart';
import 'season_selector.dart';

class IndividualPageHeader extends StatefulWidget {
  final SeasonService? seasonService;
  final String? accountId;
  final VoidCallback onSeasonSelected;
  final VoidCallback? resetSliders;

  const IndividualPageHeader(
      {super.key,
      this.seasonService,
      this.accountId,
      required this.onSeasonSelected,
      this.resetSliders});

  @override
  IndividualPageHeaderState createState() => IndividualPageHeaderState();
}

class IndividualPageHeaderState extends State<IndividualPageHeader> {
  void _refreshData() {
    widget.onSeasonSelected();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? seasonInfo;
    if (widget.seasonService != null) {
      seasonInfo = widget.seasonService!.getCurrentSeason();
    }

    final displayText = seasonInfo != null
        ? "${seasonInfo["tableName"]!} - ${modes.firstWhere(
            (element) => element["type"] == seasonInfo!["rankingType"],
          )["label"]!}"
        : "Select a Season";

    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.resetSliders == null)
            Text(
              displayText,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          const SizedBox(
            height: 12,
          ),
          Row(
            children: [
              if (widget.resetSliders == null)
                SeasonSelector(
                  seasonService: widget.seasonService!,
                  accountId: widget.accountId!,
                  onSeasonSelected: _refreshData,
                ),
              if (widget.resetSliders == null)
                const SizedBox(
                  width: 24,
                ),
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshData,
                label: const Text("Refresh"),
              ),
              const SizedBox(
                width: 24,
              ),
              if (widget.resetSliders != null)
                FilledButton.icon(
                  icon: const Icon(Icons.settings_backup_restore_rounded),
                  onPressed: () {
                    widget.resetSliders!();
                  },
                  label: const Text("Reset Sliders"),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
