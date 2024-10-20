class SeasonService {
  Map<String, dynamic>? _currentSeason;

  Map<String, dynamic>? getCurrentSeason() {
    return _currentSeason;
  }

  void setCurrentSeason(Map<String, dynamic>? season) {
    _currentSeason = season;
  }
}
