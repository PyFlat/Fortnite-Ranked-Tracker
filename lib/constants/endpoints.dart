class Endpoints {
  static const String accountsService =
      'https://account-public-service-prod.ol.epicgames.com/account/api';
  static const String habaneroService =
      'https://fn-service-habanero-live-public.ogs.live.on.epicgames.com/api/v1/games/fortnite';
  static const String eventsService =
      'https://events-public-service-live.ol.epicgames.com/api/v1';

  static const String userSearch =
      "https://user-search-service-prod.ol.epicgames.com/api/v1/search/{accountId}";

  static const String fortniteContent =
      "https://fortnitecontent-website-prod07.ol.epicgames.com/content/api";

  static const String userByAccId = "$accountsService/public/account";

  static const String userByName =
      "$accountsService/public/account/displayName/{displayName}";

  static const String userByNameExt =
      "$accountsService/public/account/lookup/externalAuth/{authType}/displayName/{displayName}?caseInsensitive=true";

  static const String authenticate = "$accountsService/oauth/token";

  static const String createDeviceAuth =
      "$accountsService/public/account/{accountId}/deviceAuth";

  static const String activeTracks =
      "$habaneroService/tracks/activeBy/{activeBy}";

  static const String bulkProgress =
      "$habaneroService/trackprogress/byAccountIds/{trackguid}";

  static const String singleProgress =
      "$habaneroService/trackprogress/{accountId}";

  static const String eventData =
      "$eventsService/events/Fortnite/data/{accountId}";

  static const String eventLeaderboard =
      "$eventsService/leaderboards/Fortnite/{eventId}/{eventWindowId}/{accountId}";

  static const String eventInformation =
      "$fortniteContent/pages/fortnite-game/tournamentinformation";

  static const String battlePassData =
      "https://www.fortnite.com/en-US/api/battle-pass-data";

  static const String accountAvatar =
      "https://avatar-service-prod.identity.live.on.epicgames.com/v1/avatar/fortnite/ids";

  static const String skinIcon =
      "https://fortnite-api.com/images/cosmetics/br/{skinId}/smallicon.png";

  static const String serverStatus =
      "http://lightswitch-public-service-prod.ol.epicgames.com/lightswitch/api/service/fortnite/status";
}
