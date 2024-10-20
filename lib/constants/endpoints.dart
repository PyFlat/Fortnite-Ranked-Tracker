class Endpoints {
  static const baseUrl = "http://localhost:3000";

  static const afterRegister = "$baseUrl/auth/register";

  static const searchByQuery = "$baseUrl/api/search/query";

  static const singleProgress = "$baseUrl/api/ranked/single-progress";

  static const subscribe = "$baseUrl/api/ranked/subscribe";

  static const playerTracking = "$baseUrl/api/database/player-tracking";

  static const playerExisting = "$baseUrl/api/database/player-existing";

  static const updatePlayer = "$baseUrl/api/database/update-player";

  static const nickName = "$baseUrl/api/database/nick-name";

  static const accounts = "$baseUrl/api/database/accounts";

  static const trackedSeasons = "$baseUrl/api/database/tracked-seasons";

  static const getSeason = "$baseUrl/api/database/season";
}
