class Endpoints {
  static const String baseUrl =
      'https://account-public-service-prod.ol.epicgames.com/account/api';
  static const String baseUrl2 =
      'https://fn-service-habanero-live-public.ogs.live.on.epicgames.com/api';

  static const String userSearch =
      "https://user-search-service-prod.ol.epicgames.com/api/v1/search/{accountId}";

  static const String userByAccId = "$baseUrl/public/account";

  static const String userByName =
      "$baseUrl/public/account/displayName/{displayName}";

  static const String userByNameExt =
      "$baseUrl/public/account/lookup/externalAuth/{authType}/displayName/{displayName}?caseInsensitive=true";

  static const String authenticate = "$baseUrl/oauth/token";

  static const String createDeviceAuth =
      "$baseUrl/public/account/{accountId}/deviceAuth";

  static const String activeTracks =
      "$baseUrl2/v1/games/fortnite/tracks/activeBy/{activeBy}";

  static const String bulkProgress =
      "$baseUrl2/v1/games/fortnite/trackprogress/byAccountIds/{trackguid}";

  static const String singleProgress =
      "$baseUrl2/v1/games/fortnite/trackprogress/{accountId}";

  static const String battlePassData =
      "https://www.fortnite.com/en-US/api/battle-pass-data";

  static const String accountAvatar =
      "https://avatar-service-prod.identity.live.on.epicgames.com/v1/avatar/fortnite/ids";

  static const String skinIcon =
      "https://fortnite-api.com/images/cosmetics/br/{skinId}/smallicon.png";
}
