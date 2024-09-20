import 'package:flutter/material.dart';

class HoverableRegionItem extends StatefulWidget {
  final String regionLabel;
  final String sessionTime;
  final bool isLive;
  final bool isSoon;
  final VoidCallback onTap;

  const HoverableRegionItem({
    super.key,
    required this.regionLabel,
    required this.sessionTime,
    required this.isLive,
    required this.isSoon,
    required this.onTap,
  });

  @override
  HoverableRegionItemState createState() => HoverableRegionItemState();
}

class HoverableRegionItemState extends State<HoverableRegionItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isHovered
                  ? [const Color(0xFF2E3B4E), const Color(0xFF485563)]
                  : [const Color(0xFF1F2A37), const Color(0xFF34495E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.regionLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.isLive
                          ? Colors.red
                          : widget.isSoon
                              ? Colors.orange
                              : null,
                    ),
                  ),
                  Text(
                    widget.sessionTime,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.isLive
                          ? Colors.redAccent
                          : widget.isSoon
                              ? Colors.orangeAccent
                              : Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
