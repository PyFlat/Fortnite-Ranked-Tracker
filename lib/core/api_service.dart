import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';

class ApiService {
  static String addPathParams(String template, Map<String, String> pathParams) {
    String formattedUrl = template;
    pathParams.forEach((key, value) {
      formattedUrl = formattedUrl.replaceAll('{$key}', value);
    });
    return formattedUrl;
  }

  static String interpolate(String string, List<String> params) {
    String result = string;
    for (int i = 0; i < params.length; i++) {
      result = result.replaceAll('%${i + 1}\$', params[i]);
    }
    return result;
  }

  static Future<String> postData(
      String url, dynamic body, String headerAuthorization, String contentType,
      {Map<String, String> pathParams = const {},
      Map<String, String> queryParams = const {}}) async {
    final headers = {
      'Authorization': headerAuthorization,
    };
    if (body != null && body.isNotEmpty) {
      headers['Content-Type'] = contentType;
    }

    String urlEnd = pathParams.isEmpty ? url : addPathParams(url, pathParams);

    try {
      final response = await Dio().post(urlEnd,
          queryParameters: queryParams,
          options: Options(headers: headers, responseType: ResponseType.bytes),
          data: body);

      if (response.statusCode == 200) {
        return utf8.decode(response.data);
      } else {
        return "Error occurred: ${utf8.decode(response.data)}";
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print(utf8.decode(e.response!.data));
      } else {
        print(e.message);
      }
      return "[]";
    }
  }

  static Future<String> getData(String url, String headerAuthorization,
      {Map<String, String> pathParams = const {},
      Map<String, String> queryParams = const {}}) async {
    String urlEnd = pathParams.isEmpty ? url : addPathParams(url, pathParams);
    Response response;
    try {
      response = await Dio().get(
        urlEnd,
        queryParameters: queryParams,
        options: Options(
            headers: {"Authorization": headerAuthorization},
            responseType: ResponseType.bytes),
      );
      return utf8.decode(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        print(utf8.decode(e.response!.data));
      } else {
        print(e.message);
      }
      return "[]";
    }
  }
}
