import 'dart:math';

import 'package:intl/intl.dart';

import '../constants/constants.dart';

double convertProgressForUnreal(double x) {
  if (x < 1e6) {
    double logValue = log(x) / ln10;
    return 1 - 1 / pow(2, (6 - logValue));
  } else {
    return 0;
  }
}

String formatDateTime(String datetime) {
  DateTime parsed = DateTime.parse(datetime).toLocal();
  String formattedDate = DateFormat('dd.MM.yyyy HH:mm:ss').format(parsed);
  return formattedDate;
}

Map<String, dynamic>? getGameModeValues(Map item, String gameMode) {
  return item[gameMode] as Map<String, dynamic>?;
}

String? getStringValue(Map<String, dynamic>? values, String key) {
  return values?[key] as String?;
}

double? getDoubleValue(Map<String, dynamic>? values, String key) {
  return (values?[key] as num?)?.toDouble();
}

int? getIntValue(Map<String, dynamic>? values, String key) {
  return (values?[key] as num?)?.toInt();
}

String? getImageAssetPath(Map<String, dynamic>? values) {
  if (getStringValue(values, 'Rank') == null) {
    return null;
  }
  return 'assets/ranked-images/${getStringValue(values, 'Rank')?.toLowerCase().replaceAll(" ", "")}.png';
}

String prettifySeasonString(String inputStr) {
  List<String> segments = inputStr.split('_');
  if (segments.length < 4) {
    throw ArgumentError('Invalid part format');
  }
  String chapter = segments[1];
  String season = segments[3];
  return 'Chapter $chapter Season $season';
}

const List<Map<String, String>> modes = [
  {
    'key': 'battleRoyale',
    'label': 'Battle Royale',
    'short': 'BR',
    'type': 'ranked-br'
  },
  {
    'key': 'zeroBuild',
    'label': 'Zero Build',
    'short': 'ZB',
    'type': 'ranked-zb'
  },
  {
    'key': 'rocketRacing',
    'label': 'Rocket Racing',
    'short': 'RR',
    'type': 'delmar-competitive'
  },
  {
    'key': 'reload',
    'label': 'Reload',
    'short': 'RL',
    'type': 'ranked_blastberry_build'
  },
  {
    'key': 'reloadZeroBuild',
    'label': 'Reload Zero Build',
    'short': 'RLZB',
    'type': 'ranked_blastberry_nobuild'
  },
  {
    'key': 'ballistic',
    'label': 'Ballistic',
    'short': 'BL',
    'type': 'ranked-feral'
  },
  {'key': 'og', 'label': 'OG', 'short': 'OG', 'type': 'ranked-figment-build'},
  {
    'key': 'ogZeroBuild',
    'label': 'OG Zero Build',
    'short': 'OGZB',
    'type': 'ranked-figment-nobuild'
  },
  {
    'key': 'gatewayLTM',
    'label': 'Gateway LTM',
    'short': 'GLTM',
    'type': 'ranked-bling'
  },
  {
    'key': 'gatewayLTMZB',
    'label': 'Gateway LTM Zero Build',
    'short': 'GLTMZB',
    'type': 'ranked-bling-nobuild'
  }
];

Map<String, String> splitAndPrettifySeasonString(String inputStr) {
  int lastUnderscoreIndex = inputStr.lastIndexOf("_");

  String firstPart = inputStr.substring(0, lastUnderscoreIndex);
  String secondPart = inputStr.substring(lastUnderscoreIndex + 1).toUpperCase();

  return {
    "season": prettifySeasonString(firstPart),
    "mode": modes.firstWhere((mode) => mode['short'] == secondPart)['label']!
  };
}

String? getRegionNameByEventId(String inputStr) {
  if (Constants.regionRegex.hasMatch(inputStr)) {
    RegExpMatch match = Constants.regionRegex.firstMatch(inputStr)!;
    return match.namedGroup("region")!;
  }
  return null;
}
