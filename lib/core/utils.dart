import 'dart:math';

import 'package:intl/intl.dart';

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
  return 'assets/ranked-images/${getStringValue(values, 'Rank')?.toLowerCase().replaceAll(" ", "")}.png';
}
