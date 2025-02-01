class Endpoints {
  static const baseUrl = "http://localhost:3000";

  static const afterRegister = "$baseUrl/auth/register";

  static const searchByQuery = "$baseUrl/api/search/query";

  static const singleProgress = "$baseUrl/api/ranked/single-progress";

  static const subscribe = "$baseUrl/api/ranked/subscribe";

  static const dashboardData = "$baseUrl/api/ranked/dashboard-data";

  static const playerTracking = "$baseUrl/api/database/player-tracking";

  static const playerExisting = "$baseUrl/api/database/player-existing";

  static const updatePlayer = "$baseUrl/api/database/update-player";

  static const nickName = "$baseUrl/api/database/nick-name";

  static const accounts = "$baseUrl/api/database/accounts";

  static const trackedSeasons = "$baseUrl/api/database/tracked-seasons";

  static const getSeason = "$baseUrl/api/database/season";

  static const eventInfo = "$baseUrl/api/tournaments/eventInfo";

  static const eventInfoHistory = "$baseUrl/api/tournaments/eventInfoHistory";

  static const eventLeaderboard = "$baseUrl/api/tournaments/eventLeaderboard";

  static const fetchLeaderboard = "$baseUrl/api/tournaments/fetchLeaderboard";

  static const eventScoringRules = "$baseUrl/api/tournaments/scoringRules";

  static const eventEntryInfo = "$baseUrl/api/tournaments/eventEntryInfo";
}
