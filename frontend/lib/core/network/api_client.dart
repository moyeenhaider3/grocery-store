import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Returns null when [baseUrl] is usable, otherwise a human readable message.
String? apiConfigError(String baseUrl) {
  final uri = Uri.tryParse(baseUrl);
  if (uri != null && uri.hasScheme && uri.host.isNotEmpty) return null;
  return 'API_BASE_URL is not set. Start the app with --dart-define=API_BASE_URL=<backend base URL ending in /api> (see README).';
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final List<dynamic>? details;

  const ApiException(this.message, {this.statusCode, this.code, this.details});

  bool get isUnauthorized => statusCode == 401;
  bool get endsSession => statusCode == 401 || code == 'ACCOUNT_BLOCKED';

  factory ApiException.fromDio(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) {
      final response = error.response;
      final data = response?.data;
      if (response != null && data is Map) {
        return ApiException(
          (data['message'] as String?) ?? 'Server error occurred',
          statusCode: response.statusCode,
          code: data['code'] as String?,
          details: data['errors'] is List ? data['errors'] as List<dynamic> : null,
        );
      }
      if (response != null) {
        return ApiException('Server error occurred', statusCode: response.statusCode);
      }
      return const ApiException('Cannot reach the server. Please try again.');
    }
    return ApiException(error.toString());
  }

  @override
  String toString() => message;
}

class ApiClient {
  // Supplied at build/run time: --dart-define=API_BASE_URL=<backend base URL ending in /api>
  static const String baseUrl = String.fromEnvironment('API_BASE_URL');
  static const String tokenKey = 'jwt_token';

  final SharedPreferences prefs;
  late final Dio dio;

  /// Called when an authenticated request shows the session is over (wired in DI).
  void Function()? onUnauthorized;

  ApiClient(this.prefs) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final isCredentialCall = options.path == '/auth/login' || options.path == '/auth/signup';
          final token = prefs.getString(tokenKey);
          if (!isCredentialCall && token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          final hadToken = e.requestOptions.headers.containsKey('Authorization');
          final status = e.response?.statusCode;
          final data = e.response?.data;
          final blocked = status == 403 && data is Map && data['code'] == 'ACCOUNT_BLOCKED';
          if (hadToken && (status == 401 || blocked)) {
            await prefs.remove(tokenKey);
            if (e.requestOptions.path != '/auth/logout') {
              onUnauthorized?.call();
            }
          }
          return handler.next(e);
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          requestHeader: false,
          responseHeader: false,
        ),
      );
    }
  }
}
