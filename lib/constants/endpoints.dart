class Endpoints {
  static const String baseUrl =
      'https://account-public-service-prod.ol.epicgames.com/account/api';
  static const String baseUrl2 =
      'https://fn-service-habanero-live-public.ogs.live.on.epicgames.com/api';

  static const String userSearch =
      "https://user-search-service-prod.ol.epicgames.com/api/v1/search/%1\$?platform=%2\$&prefix=%3\$";

  static const String userByAccId = "$baseUrl/public/account?accountId=%1\$";

  static const String userByName = "$baseUrl/public/account/displayName/%1\$";

  static const String userByNameExt =
      "$baseUrl/public/account/lookup/externalAuth/%1\$/displayName/%2\$?caseInsensitive=true";

  static const String authenticate = "$baseUrl/oauth/token";

  static const String createDeviceAuth =
      "$baseUrl/public/account/%1\$/deviceAuth";

  static const String activeTracks =
      "$baseUrl2/v1/games/fortnite/tracks/activeBy/%1\$";

  static const String bulkProgress =
      "$baseUrl2/v1/games/fortnite/trackprogress/byAccountIds/%1\$";

  static const String singleProgress =
      "$baseUrl2/v1/games/fortnite/trackprogress/%1\$?endsAfter=%2\$";

  static const String battlePassData =
      "https://www.fortnite.com/en-US/api/battle-pass-data";
}
