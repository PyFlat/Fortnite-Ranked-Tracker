import 'dart:convert';
import 'dart:io';

import '../constants/constants.dart';
import '../constants/endpoints.dart';
import '../core/auth_provider.dart';
import '../screens/home_screen.dart';
import '../core/api_service.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final controller = WebViewController();
  bool _isAuthorizationInProgress = false;

  @override
  void initState() {
    super.initState();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.addJavaScriptChannel("Print",
        onMessageReceived: _handleMessageReceived);
    controller.setNavigationDelegate(NavigationDelegate(
      onPageFinished: (url) {
        if (url.startsWith("https://www.epicgames.com/account/personal")) {
          controller.runJavaScript(
              """fetch("https://www.epicgames.com/id/api/redirect?clientId=3446cd72694c4a4485d81b77adbb2141&responseType=code")
                  .then(response => response.json())
                  .then(data => { Print.postMessage(data.authorizationCode); });""");
        }
      },
    ));
    controller
        .loadRequest(Uri.parse("https://www.epicgames.com/account/personal"));
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
    String response = await ApiService.postData(Endpoints.authenticate, body,
        Constants.basicAuth, Constants.dataUrlEncoded);

    Map<String, dynamic> jsonObject = jsonDecode(response);

    String accessToken = jsonObject["access_token"];
    String accountId = jsonObject["account_id"];

    final params = [accountId];

    String url = ApiService.interpolate(Endpoints.createDeviceAuth, params);

    String bearerAuth = "bearer $accessToken";

    response = await ApiService.postData(url, null, bearerAuth, "");

    jsonObject = jsonDecode(response);

    Map<String, String> deviceDataJson = {
      "grant_type": "device_auth",
      "account_id": accountId,
      "device_id": jsonObject["deviceId"],
      "secret": jsonObject["secret"]
    };
    final directory = await getApplicationSupportDirectory();
    String filePath = '${directory.path}/deviceAuthGrant.json';
    await writeToFile(filePath, jsonEncode(deviceDataJson));

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await authProvider.initializeAuth();

    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    }

    _isAuthorizationInProgress = false;
  }

  Future<void> writeToFile(String filePath, String jsonString) async {
    File file = File(filePath);

    // Write the JSON string to the file
    await file
        .writeAsString(jsonString)
        .then((file) => print('File saved: $filePath'))
        .catchError((error) => print('Error saving file: $error'));
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
