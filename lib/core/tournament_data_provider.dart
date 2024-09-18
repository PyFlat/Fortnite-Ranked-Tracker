import 'package:flutter/material.dart';
import 'tournament_service.dart';

class TournamentDataProvider with ChangeNotifier {
  List<Tournament> _data = [];
  bool _isLoading = false;

  List<Tournament> get data => _data;
  bool get isLoading => _isLoading;

  Future<void> fetchData() async {
    if (_data.isEmpty) {
      _isLoading = true;
      notifyListeners();
      _data = await TournamentService().getEventData();
      _isLoading = false;
      notifyListeners();
    }
  }
}
