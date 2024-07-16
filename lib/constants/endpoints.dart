class Endpoints {
  static const String baseUrl =
      'https://account-public-service-prod.ol.epicgames.com/account/api';
  static const String baseUrl2 =
      'https://fn-service-habanero-live-public.ogs.live.on.epicgames.com/api';

  static const String authenticate = "$baseUrl/oauth/token";

  static const String createDeviceAuth =
      "$baseUrl/public/account/%1\$/deviceAuth";

  static const String bulkProgress =
      "$baseUrl2/v1/games/%1\$/trackprogress/byAccountIds/%2\$";
}
