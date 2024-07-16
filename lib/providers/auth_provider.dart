import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import '../constants/endpoints.dart';
import '../constants/constants.dart';

class AuthProvider with ChangeNotifier {
  late String _accessToken;
  late String _refreshToken;
  late Timer _refreshTimer;

  AuthProvider() {
    _accessToken = "";
    _refreshTimer = Timer(Duration.zero, () {});
    _initAuth();
  }

  String get accessToken => _accessToken;

  Future<void> _initAuth() async {
    try {
      final authData = await _loadAuthData();
      await _authenticate(authData);
      _scheduleTokenRefresh();
    } catch (error) {
      print('Authentication failed: $error');
      throw error;
    }
  }

  Future<Map<String, dynamic>> _loadAuthData() async {
    final jsonString =
        await rootBundle.loadString('assets/deviceAuthGrant.json');
    return jsonDecode(jsonString);
  }

  Future<void> _authenticate(Map<String, dynamic> authData) async {
    final response = await http.post(
      Uri.parse(Endpoints.authenticate),
      headers: {
        'Authorization': Constants.basicAuth,
        'Content-Type': Constants.dataUrlEncoded,
      },
      body: authData,
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      _accessToken = responseData['access_token'];
      _refreshToken = responseData['refresh_token'];
      notifyListeners();
    } else {
      throw Exception('Failed to authenticate');
    }
  }

  Future<void> refreshToken() async {
    final response = await http.post(
      Uri.parse(Endpoints.authenticate),
      headers: {
        'Authorization': Constants.basicAuth,
        'Content-Type': Constants.dataUrlEncoded,
      },
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': _refreshToken,
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      _accessToken = responseData['access_token'];
      _refreshToken = responseData['refresh_token'];
      notifyListeners();
    } else {
      throw Exception('Failed to refresh token');
    }
  }

  void _scheduleTokenRefresh() {
    _refreshTimer.cancel();
    _refreshTimer = Timer(const Duration(minutes: 30), () {
      refreshToken().catchError((error) {
        print('Failed to refresh token: $error');
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }
}
