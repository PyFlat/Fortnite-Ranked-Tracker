import 'dart:convert';
import 'dart:io';

import 'package:auth_flow_example/constants/constants.dart';
import 'package:auth_flow_example/constants/endpoints.dart';
import 'package:auth_flow_example/screens/home_screen.dart';
import 'package:auth_flow_example/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const AuthScreen());
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final controller = WebViewController();

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
    final directory = await getApplicationDocumentsDirectory();
    String filePath = '${directory.path}/deviceAuthGrant.json';
    writeToFile(filePath, jsonEncode(deviceDataJson));

    switchToMainPage();
  }

  void switchToMainPage() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => HomeScreen()));

    Navigator.pop(context);
  }

  void writeToFile(String filePath, String jsonString) {
    File file = File(filePath);

    // Write the JSON string to the file
    file
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
