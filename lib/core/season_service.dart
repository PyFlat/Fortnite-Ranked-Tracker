import 'database.dart';
import 'utils.dart';

class SeasonService {
  final DataBase _database = DataBase();
  String? _currentSeason;

  Future<List<String>> fetchSeasons(String accountId) async {
    return await _database.getTrackedSeasons(accountId);
  }

  String? getCurrentSeason() {
    return _currentSeason;
  }

  void setCurrentSeason(String? season) {
    _currentSeason = season;
  }

  Map<String, String> formatSeason(String season) {
    return splitAndPrettifySeasonString(season);
  }
}
