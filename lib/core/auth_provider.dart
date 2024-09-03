import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../constants/endpoints.dart';
import '../constants/constants.dart';

class AuthProvider with ChangeNotifier {
  late String _accessToken;
  late String _accountId;
  late String _displayName;
  late String _refreshToken;
  late Talker _talker;
  Timer? _refreshTimer; // Make this nullable to handle initial state
  bool _isInitialized = false;

  AuthProvider(Talker talker) {
    _talker = talker;
    _accessToken = "";
    _initAuth();
  }

  String get accessToken => _accessToken;

  String get accountId => _accountId;

  String get displayName => _displayName;

  Future<void> initializeAuth({bool force = false}) async {
    if (!_isInitialized || force) {
      await _initAuth(force: force);
    }
  }

  Future<void> _initAuth({bool force = false}) async {
    try {
      final authData = await _loadAuthData();
      if (_accessToken.isEmpty || force) {
        await _authenticate(authData);
      }
      _accountId = authData["account_id"];
      _scheduleTokenRefresh();
      _isInitialized = true;
    } catch (error) {
      if (error is PathNotFoundException) {
        _accessToken = "";
      } else if (error is SocketException) {
      } else {
        _talker.error('Authentication failed: $error');
      }
    }
  }

  Future<Map<String, dynamic>> _loadAuthData() async {
    final directory = await getApplicationSupportDirectory();
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
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      _accessToken = responseData['access_token'];
      _refreshToken = responseData['refresh_token'];
      _displayName = responseData['displayName'];
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
      _talker.info("Refreshed Token");
    } else {
      throw Exception('Failed to refresh token');
    }
  }

  void _scheduleTokenRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 20), (callback) {
      refreshToken().catchError((error) {
        if (error is! SocketException) {
          _talker.error('Failed to refresh token: $error');
        }
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
