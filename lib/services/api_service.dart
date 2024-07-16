import 'dart:async';
import 'dart:convert';
import 'package:auth_flow_example/constants/constants.dart';
import 'package:auth_flow_example/constants/endpoints.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ApiService {
  final BuildContext context;

  ApiService(this.context);

  Future<void> periodicGetRequests() async {
    Timer.periodic(Duration(seconds: 15), (Timer t) async {
      await bulkProgress();
    });
  }

  String interpolate(String string, List<String> params) {
    String result = string;
    for (int i = 0; i < params.length; i++) {
      result = result.replaceAll('%${i + 1}\$', params[i]);
    }
    return result;
  }

  Future<String> postData(String url, Map<String, List<String>> body) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final response = await http.post(Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${authProvider.accessToken}',
          'Content-Type': Constants.dataJson
        },
        body: jsonEncode(body));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return "Error occured ${response.body}";
    }
  }

  Future<String> getData(String url) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${authProvider.accessToken}',
      },
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      return "Error occured ${response.body}";
    }
  }

  Future<void> bulkProgress() async {
    const params = ["fortnite", "L1GHT5"];
    String url = interpolate(Endpoints.bulkProgress, params);
    const body = {
      "accountIds": [
        "14d18727fae2432d997b3a69ad601b3d",
        "49a809c144844feea10b90b60b27d8bc",
        "d6695a93468f4f4aaf33c14b05bcb84e",
        "64c3a96d162245a28d135ef5d85eb3e8"
      ]
    };

    //final response = await postData(url, body);

    url =
        "https://fn-service-habanero-live-public.ogs.live.on.epicgames.com/api/v1/games/fortnite/tracks/activeBy/2024-05-24T14:02:02.061163Z";

    final response2 = await getData(url);

    print(response2);
  }
}
