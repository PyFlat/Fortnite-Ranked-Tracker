import 'dart:async';
import 'package:dio/dio.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

import 'talker_service.dart';

class ApiService {
  bool _isInitialized = false;
  late Dio _dio;

  ApiService._();
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;

  Dio get dio => _dio;

  Future<void> init(Dio dio) async {
    if (!_isInitialized) {
      _dio = dio;
      _dio.interceptors.add(
        TalkerDioLogger(
          talker: talker,
          settings: TalkerDioLoggerSettings(
            responseFilter: (response) => false,
            requestFilter: (requestOptions) => false,
            errorFilter: (response) {
              Response? responseObject = response.response;
              if (responseObject != null) {
                if (responseObject.statusCode == 404) {
                  return responseObject.data["numericErrorCode"] != 18007;
                }
                return responseObject.statusCode != 429;
              } else {
                if (response.type == DioExceptionType.connectionError) {
                  return false;
                }
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
      Map<String, String> queryParams = const {},
      CancelToken? cancelToken}) async {
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
          data: body,
          cancelToken: cancelToken);

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
      } else {
        if (e.type != DioExceptionType.connectionError) {
          talker.error(e.message);
        }
      }
      return [];
    }
  }

  Future<dynamic> getData(String url, String headerAuthorization,
      {Map<String, String> pathParams = const {},
      Map<String, dynamic> queryParams = const {},
      ResponseType responseType = ResponseType.json}) async {
    String urlEnd = pathParams.isEmpty ? url : addPathParams(url, pathParams);
    Response response;
    try {
      var uri = Uri.parse(urlEnd).resolveUri(Uri(queryParameters: queryParams));
      response = await _dio.getUri(
        uri,
        options: Options(
            headers: {"Authorization": headerAuthorization},
            responseType: responseType),
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
      } else {
        if (e.type != DioExceptionType.connectionError) {
          talker.error(e.message);
        }
      }
      return [];
    }
  }
}
