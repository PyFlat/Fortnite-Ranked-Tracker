class RankData {
  final String? progressText;
  final double? progress;
  final String? lastProgress;
  final String? lastChanged;
  final int? dailyMatches;
  final String? rankImagePath;
  final String? rank;
  final String? oldRank;
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
    this.oldRank,
    required this.active,
    this.tracking,
  });
}
