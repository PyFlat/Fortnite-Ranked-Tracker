class Constants {
  static const String basicAuth =
      "basic YWY0M2RjNzFkZDkxNDUyMzk2ZmNkZmZiZDdhOGU4YTk6NFlYdlNFQkxGUlBMaDFoekdaQWtmT2k1bXF1cEZvaFo==";

  static const String dataJson = "application/json";
  static const String dataUrlEncoded = "application/x-www-form-urlencoded";

  static RegExp regionRegex = RegExp(r'S\d+_\w+_(?<region>[A-Z]+)(\S+)?');

  static const List<String> ranks = [
    "Bronze I",
    "Bronze II",
    "Bronze III",
    "Silver I",
    "Silver II",
    "Silver III",
    "Gold I",
    "Gold II",
    "Gold III",
    "Platinum I",
    "Platinum II",
    "Platinum III",
    "Diamond I",
    "Diamond II",
    "Diamond III",
    "Elite",
    "Champion",
    "Unreal"
  ];

  static const Map<String, String> regions = {
    "EU": "Europe",
    "NAC": "NA Central",
    "NAE": "NA East",
    "NAW": "NA West",
    "ASIA": "Asia",
    "ME": "Middle East",
    "BR": "Brazil",
    "OCE": "Oceania",
    "ONSITE": "All"
  };

  static const String defaultSkinId =
      "CID_A_402_Athena_Commando_F_RebirthFresh";
}
