import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fortnite_ranked_tracker/screens/main_screen.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../constants/constants.dart';
import '../constants/endpoints.dart';
import '../core/epic_auth_provider.dart';
import '../core/api_service.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AuthScreen extends StatefulWidget {
  final EpicAuthProvider authProvider;
  final Talker talker;
  final Dio dio;

  const AuthScreen(
      {super.key,
      required this.authProvider,
      required this.talker,
      required this.dio});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final controller = WebViewController();
  bool _isAuthorizationInProgress = false;

  @override
  void initState() {
    super.initState();
    _initializeApiService();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.addJavaScriptChannel("Print",
        onMessageReceived: _handleMessageReceived);
    controller.setNavigationDelegate(NavigationDelegate(
      onPageFinished: (url) {
        if (url.startsWith("https://www.epicgames.com/account/personal")) {
          controller.runJavaScript(
              """fetch("https://www.epicgames.com/id/api/redirect?clientId=af43dc71dd91452396fcdffbd7a8e8a9&responseType=code")
                  .then(response => response.json())
                  .then(data => { Print.postMessage(data.authorizationCode); });""");
        }
      },
    ));
    controller
        .loadRequest(Uri.parse("https://www.epicgames.com/account/personal"));
  }

  Future<void> _initializeApiService() async {
    await ApiService().init(widget.talker, widget.authProvider, widget.dio);
  }

  void _handleMessageReceived(JavaScriptMessage jsMessage) {
    if (_isAuthorizationInProgress) return;

    _isAuthorizationInProgress = true;
    String msg = jsMessage.message;

    createDeviceAuth(msg);
  }

  Future<void> createDeviceAuth(String authorizationcode) async {
    Map<String, dynamic> body = {
      "grant_type": "authorization_code",
      "code": authorizationcode,
    };
    dynamic jsonObject = await ApiService().postData(Endpoints.authenticate,
        body, Constants.basicAuth, Constants.dataUrlEncoded);

    String accessToken = jsonObject["access_token"];
    String accountId = jsonObject["account_id"];

    String bearerAuth = "bearer $accessToken";

    jsonObject = await ApiService().postData(
        Endpoints.createDeviceAuth, null, bearerAuth, "",
        pathParams: {"accountId": accountId});

    Map<String, String> deviceDataJson = {
      "grant_type": "device_auth",
      "account_id": accountId,
      "device_id": jsonObject["deviceId"],
      "secret": jsonObject["secret"],
      "token_type": "eg1"
    };
    final directory = await getApplicationSupportDirectory();
    String filePath = '${directory.path}/deviceAuthGrant.json';
    await writeToFile(filePath, jsonEncode(deviceDataJson));

    if (mounted) {
      final authProvider =
          Provider.of<EpicAuthProvider>(context, listen: false);
      await authProvider.initializeAuth();

      if (mounted) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => MainScreen(
                    authProvider: authProvider,
                    talker: widget.talker,
                    dio: widget.dio)));
      }
    }

    _isAuthorizationInProgress = false;
  }

  Future<void> writeToFile(String filePath, String jsonString) async {
    File file = File(filePath);

    await file
        .writeAsString(jsonString)
        .then((file) => widget.talker.info('File saved: $filePath'))
        .catchError(
            (error) => widget.talker.error('Error saving file: $error'));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: WebViewWidget(controller: controller),
      ),
    );
  }
}
