import 'package:flutter/material.dart';

import '../core/season_service.dart';
import 'season_selector.dart';

class IndividualPageHeader extends StatefulWidget {
  final SeasonService _seasonService;
  final String accountId;
  final VoidCallback onSeasonSelected;
  final VoidCallback? resetSliders;

  const IndividualPageHeader(
      {Key? key,
      required SeasonService seasonService,
      required this.accountId,
      required this.onSeasonSelected,
      this.resetSliders})
      : _seasonService = seasonService,
        super(key: key);

  @override
  _IndividualPageHeaderState createState() => _IndividualPageHeaderState();
}

class _IndividualPageHeaderState extends State<IndividualPageHeader> {
  void _refreshData() {
    widget.onSeasonSelected();
  }

  @override
  Widget build(BuildContext context) {
    final seasonInfo = widget._seasonService.getCurrentSeason() != null
        ? widget._seasonService
            .formatSeason(widget._seasonService.getCurrentSeason()!)
        : null;

    final displayText = seasonInfo != null
        ? "${seasonInfo["season"]!} - ${seasonInfo["mode"]!}"
        : "Select a Season";

    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayText,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          SizedBox(
            height: 12,
          ),
          Row(
            children: [
              SeasonSelector(
                seasonService: widget._seasonService,
                accountId: widget.accountId,
                onSeasonSelected: _refreshData,
              ),
              SizedBox(
                width: 24,
              ),
              FilledButton.icon(
                icon: Icon(Icons.refresh),
                onPressed: _refreshData,
                label: const Text("Refresh"),
              ),
              SizedBox(
                width: 24,
              ),
              if (widget.resetSliders != null)
                FilledButton.icon(
                  icon: Icon(Icons.settings_backup_restore_rounded),
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
