import 'dart:async';
import 'dart:convert';
import 'package:auth_flow_example/constants/constants.dart';
import 'package:auth_flow_example/constants/endpoints.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class ApiService {
  static Future<void> periodicGetRequests(BuildContext context) async {
    Timer.periodic(Duration(seconds: 15), (Timer t) async {
      await bulkProgress(context);
    });
  }

  static String interpolate(String string, List<String> params) {
    String result = string;
    for (int i = 0; i < params.length; i++) {
      result = result.replaceAll('%${i + 1}\$', params[i]);
    }
    return result;
  }

  static Future<String> postData(String url, dynamic body,
      String headerAuthorization, String contentType) async {
    final headers = {
      'Authorization': headerAuthorization,
    };
    if (body != null && body.isNotEmpty) {
      headers['Content-Type'] = contentType;
    }

    final response = body == null || body.isEmpty
        ? await http.post(Uri.parse(url), headers: headers)
        : await http.post(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode == 200) {
      return response.body;
    } else {
      return "Error occurred: ${response.body}";
    }
  }

  static Future<String> getData(String url, String headerAuthorization) async {
    Map<String, String> headers = {
      'Authorization': headerAuthorization,
    };
    final response = await http.get(Uri.parse(url),
        headers: headerAuthorization.isNotEmpty ? headers : null);

    if (response.statusCode == 200) {
      return response.body;
    } else {
      return "Error occurred ${response.body}";
    }
  }

  static Future<dynamic> bulkProgress(BuildContext context) async {
    const params = ["fortnite", "N4PK1N"];
    String url = interpolate(Endpoints.bulkProgress, params);
    const body = {
      "accountIds": [
        "14d18727fae2432d997b3a69ad601b3d",
        "49a809c144844feea10b90b60b27d8bc",
        "d6695a93468f4f4aaf33c14b05bcb84e",
        "64c3a96d162245a28d135ef5d85eb3e8"
      ]
    };

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    String headerAuthorization = 'Bearer ${authProvider.accessToken}';

    final response = await postData(
        url, jsonEncode(body), headerAuthorization, Constants.dataJson);

    return jsonDecode(response);
  }
}
