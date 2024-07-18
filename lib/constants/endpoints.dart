class Endpoints {
  static const String baseUrl =
      'https://account-public-service-prod.ol.epicgames.com/account/api';
  static const String baseUrl2 =
      'https://fn-service-habanero-live-public.ogs.live.on.epicgames.com/api';

  static const String authenticate = "$baseUrl/oauth/token";

  static const String createDeviceAuth =
      "$baseUrl/public/account/%1\$/deviceAuth";

  static const String bulkProgress =
      "$baseUrl2/v1/games/fortnite/trackprogress/byAccountIds/%1\$";

  static const String battlePassData =
      "https://www.fortnite.com/en-US/api/battle-pass-data";
}
