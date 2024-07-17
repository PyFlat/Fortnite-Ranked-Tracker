import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../constants/endpoints.dart';
import '../constants/constants.dart';

class AuthProvider with ChangeNotifier {
  late String _accessToken;
  late String _refreshToken;
  late Timer _refreshTimer;
  bool _isInitialized = false;

  AuthProvider() {
    _accessToken = "";
    _refreshTimer = Timer(Duration.zero, () {});
    _initAuth();
  }

  String get accessToken => _accessToken;

  Future<void> initializeAuth() async {
    if (!_isInitialized) {
      await _initAuth();
    }
  }

  Future<void> _initAuth() async {
    try {
      final authData = await _loadAuthData();
      if (_accessToken.isEmpty) {
        await _authenticate(authData);
      }
      _scheduleTokenRefresh();
      _isInitialized = true;
    } catch (error) {
      if (error is PathNotFoundException) {
        _accessToken = "";
      } else {
        print('Authentication failed: $error');
      }
    }
  }

  Future<Map<String, dynamic>> _loadAuthData() async {
    final directory = await getApplicationDocumentsDirectory();
    File file = File('${directory.path}/deviceAuthGrant.json');
    String authGrant = await file.readAsString();
    return jsonDecode(authGrant);
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
