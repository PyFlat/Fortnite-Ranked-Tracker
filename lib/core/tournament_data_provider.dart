import 'package:flutter/material.dart';
import 'tournament_service.dart';

class TournamentDataProvider with ChangeNotifier {
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get data => _data;
  bool get isLoading => _isLoading;

  Future<void> fetchData({bool force = false}) async {
    if (data.isEmpty || force) {
      _isLoading = true;
      notifyListeners();
      await TournamentService().fetchEvents();
      _data = await TournamentService().getEvents();
      _isLoading = false;
      notifyListeners();
    }
  }
}
