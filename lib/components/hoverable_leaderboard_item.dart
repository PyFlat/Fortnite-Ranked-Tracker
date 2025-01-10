import 'package:flutter/material.dart';

class HoverableLeaderboardItem extends StatefulWidget {
  final dynamic entry;
  final int index;
  final VoidCallback onTap;

  const HoverableLeaderboardItem({
    required this.entry,
    required this.index,
    required this.onTap,
    super.key,
  });

  @override
  HoverableLeaderboardItemState createState() =>
      HoverableLeaderboardItemState();
}

class HoverableLeaderboardItemState extends State<HoverableLeaderboardItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _updateHoverState(true),
      onExit: (_) => _updateHoverState(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          children: [
            Container(
              height: 120,
              margin:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              decoration: _buildLeaderboardItemDecoration(widget.entry),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRankCircle(widget.entry),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDisplayNameTags(widget.entry),
                          _buildStatChips(widget.entry),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isHovered)
              Container(
                height: 120,
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(16.0),
                ),
              )
          ],
        ),
      ),
    );
  }

  void _updateHoverState(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
  }

  Widget _buildStatChips(dynamic entry) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: [
        _buildStatChip('Points', entry["points"],
            const Icon(Icons.star_rounded, color: Colors.amber)),
        _buildStatChip(
            'Rounds', entry["matches"], const Icon(Icons.loop_rounded)),
        _buildStatChip(
          'Wins',
          entry["victories"],
          const Icon(Icons.emoji_events_rounded, color: Colors.amber),
        ),
        _buildStatChip(
            "Kills",
            entry["elims"],
            const Icon(
              Icons.close_rounded,
              color: Colors.redAccent,
            ))
      ],
    );
  }

  Widget _buildStatChip(String label, dynamic value, Icon icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 4.0),
          Text(
            '$label: $value',
            style: const TextStyle(
              fontSize: 14.0,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankCircle(dynamic entry) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _getLeaderboardItemGradient(entry["rank"] - 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .5),
            blurRadius: 6.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 40,
        backgroundColor: Colors.transparent,
        child: Text(
          entry["rank"].toString(),
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            color: entry["rank"] <= 2 ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayNameTags(dynamic entry) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: (entry["accounts"] as List)
          .map((displayName) => _buildPillTag(displayName))
          .toList(),
    );
  }

  Widget _buildPillTag(String displayName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.blueGrey[800],
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(
        displayName,
        style: const TextStyle(
          fontSize: 16.0,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  BoxDecoration _buildLeaderboardItemDecoration(dynamic entry) {
    return BoxDecoration(
      color: Colors.grey[850],
      borderRadius: BorderRadius.circular(16.0),
      boxShadow: const [
        BoxShadow(
          color: Colors.black54,
          blurRadius: 8.0,
          offset: Offset(0, 4),
        ),
      ],
      gradient: _getLeaderboardItemGradient(entry["rank"] - 1),
      border: Border.all(color: Colors.white, width: entry["rank"] > 3 ? 2 : 3),
    );
  }

  LinearGradient _getLeaderboardItemGradient(int index) {
    switch (index) {
      case 0:
        return const LinearGradient(
          colors: [Colors.amber, Colors.deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 1:
        return const LinearGradient(
          colors: [Colors.grey, Colors.blueGrey],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 2:
        return const LinearGradient(
          colors: [Color(0xffce8946), Colors.brown],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: [
            Colors.blueAccent.withValues(alpha: .3),
            Colors.deepPurple.withValues(alpha: .3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}
