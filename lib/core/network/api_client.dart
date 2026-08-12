import 'dart:io';

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_config.dart';
import 'mock_api.dart';

/// Exception with a user-friendly message extracted from the backend response.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// True when running under `flutter test`.
bool get _isTestEnvironment => Platform.environment.containsKey('FLUTTER_TEST');

/// Thin wrapper around [Dio] that handles the base URL, the JWT bearer token
/// and consistent error reporting for the ERP backend.
///
/// When the real backend cannot be reached (widget tests, demo mode offline)
/// the app transparently falls back to the in-memory [MockApi] so the whole
/// flow keeps working with seeded data.
class ApiClient {
  ApiClient._();

  static final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final token = await TokenStorage.readToken();
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              handler.next(options);
            },
          ),
        );

  static Future<dynamic> getData(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      () => _dio.get<dynamic>(path, queryParameters: queryParameters),
      'GET',
      path,
    );
  }

  static Future<dynamic> postData(String path, {Object? data}) {
    final body = data is Map<String, dynamic> ? data : null;
    return _request(
      () => _dio.post<dynamic>(path, data: data),
      'POST',
      path,
      data: body,
    );
  }

  static Future<dynamic> putData(String path, {Object? data}) {
    final body = data is Map<String, dynamic> ? data : null;
    return _request(
      () => _dio.put<dynamic>(path, data: data),
      'PUT',
      path,
      data: body,
    );
  }

  /// Uploads a local file (for example a product photo) as multipart form
  /// data. When the backend is unreachable the in-memory [MockApi] records a
  /// synthetic URL so the offline demo keeps working.
  static Future<dynamic> postMultipart(
    String path, {
    required String fileField,
    required String filePath,
  }) async {
    if (_isTestEnvironment) {
      return _runMock(
        'POST',
        path,
        {'__multipart__': true, 'fileField': fileField, 'filePath': filePath},
      );
    }

    Future<Response<dynamic>> run() async {
      final formData = FormData.fromMap({
        fileField: await MultipartFile.fromFile(filePath),
      });
      return _dio.post<dynamic>(path, data: formData);
    }

    try {
      final response = await run();
      return response.data;
    } on DioException catch (e) {
      if (_isNetworkFailure(e)) {
        return _runMock(
          'POST',
          path,
          {'__multipart__': true, 'fileField': fileField, 'filePath': filePath},
        );
      }
      throw _mapError(e);
    }
  }

  static Future<dynamic> _request(
    Future<Response<dynamic>> Function() run,
    String method,
    String path, {
    Map<String, dynamic>? data,
  }) async {
    if (_isTestEnvironment) {
      return _runMock(method, path, data);
    }

    try {
      final response = await run();
      return response.data;
    } on DioException catch (e) {
      if (_isNetworkFailure(e)) {
        return _runMock(method, path, data);
      }
      throw _mapError(e);
    }
  }

  static dynamic _runMock(String method, String path, Map<String, dynamic>? data) {
    try {
      return MockApi.instance.handle(method, path, data: data);
    } on MockApiException catch (e) {
      throw ApiException(e.message, statusCode: e.statusCode);
    }
  }

  static bool _isNetworkFailure(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
      case DioExceptionType.transformTimeout:
        return true;
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
        return false;
    }
  }

  static ApiException _mapError(DioException e) {
    var message = 'Something went wrong. Please try again.';

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'The request timed out. Please try again.';
        break;
      case DioExceptionType.connectionError:
        message =
            'Cannot reach the server. Check your connection and try again.';
        break;
      case DioExceptionType.badCertificate:
        message = 'The server certificate could not be validated.';
        break;
      case DioExceptionType.cancel:
        message = 'The request was cancelled.';
        break;
      case DioExceptionType.badResponse:
        final data = e.response?.data;
        if (data is Map &&
            data['message'] is String &&
            (data['message'] as String).isNotEmpty) {
          message = data['message'] as String;
        } else if (e.response?.statusCode == 401) {
          message = 'Your session has expired. Please log in again.';
        } else if (e.response?.statusCode == 403) {
          message = 'You do not have permission to perform this action.';
        } else if (e.response?.statusCode == 404) {
          message = 'The requested resource was not found.';
        } else if (e.response?.statusCode != null &&
            e.response!.statusCode! >= 500) {
          message = 'The server encountered an error. Please try again.';
        }
        break;
      case DioExceptionType.unknown:
      case DioExceptionType.transformTimeout:
        break;
    }

    return ApiException(message, statusCode: e.response?.statusCode);
  }
}
