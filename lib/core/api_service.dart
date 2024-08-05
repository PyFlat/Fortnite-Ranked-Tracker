import 'dart:async';
import 'package:dio/dio.dart';
import 'package:fortnite_ranked_tracker/core/auth_provider.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ApiService {
  bool _isInitialized = false;
  late Dio _dio;

  ApiService._();
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;

  Future<void> init(Talker talker, AuthProvider authProvider, Dio dio) async {
    if (!_isInitialized) {
      _dio = dio;
      _dio.interceptors.add(
        TalkerDioLogger(
          talker: talker,
          settings: TalkerDioLoggerSettings(
            printRequestHeaders: false,
            printResponseHeaders: false,
            printRequestData: false,
            printResponseData: false,
            errorFilter: (response) {
              Response? responseObject = response.response;
              if (responseObject != null) {
                if (responseObject.statusCode == 404) {
                  return responseObject.data["numericErrorCode"] != 18007;
                } else if (responseObject.statusCode == 401) {
                  authProvider.initializeAuth(force: true);
                }
                return responseObject.statusCode != 429;
              }
              return true;
            },
          ),
        ),
      );

      _isInitialized = true;
    }
  }

  String addPathParams(String template, Map<String, String> pathParams) {
    String formattedUrl = template;
    pathParams.forEach((key, value) {
      formattedUrl = formattedUrl.replaceAll('{$key}', value);
    });
    return formattedUrl;
  }

  Future<dynamic> postData(
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
      final response = await _dio.post(urlEnd,
          queryParameters: queryParams,
          options: Options(headers: headers, responseType: ResponseType.json),
          data: body);

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        //print(e.response!.data);
      } else {
        print(e.message);
      }
      return [];
    }
  }

  Future<dynamic> getData(String url, String headerAuthorization,
      {Map<String, String> pathParams = const {},
      Map<String, String> queryParams = const {}}) async {
    String urlEnd = pathParams.isEmpty ? url : addPathParams(url, pathParams);
    Response response;
    try {
      response = await _dio.get(
        urlEnd,
        queryParameters: queryParams,
        options: Options(
            headers: {"Authorization": headerAuthorization},
            responseType: ResponseType.json),
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        //print(e.response!.data);
      } else {
        print(e.message);
      }
      return [];
    }
  }
}
