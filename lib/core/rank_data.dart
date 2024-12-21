class RankData {
  final String? progressText;
  final double? progress;
  final String? lastProgress;
  final String? lastChanged;
  final int? dailyMatches;
  final String? rankImagePath;
  final String? rank;
  final bool active;
  final bool? tracking;

  const RankData({
    this.progressText,
    this.progress,
    this.lastProgress,
    this.lastChanged,
    this.dailyMatches,
    this.rankImagePath,
    this.rank,
    required this.active,
    this.tracking,
  });
}
