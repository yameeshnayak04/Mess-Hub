// This file sets up a centralized and powerful HTTP client using the Dio package.

import 'package:dio/dio.dart';
import 'package:mess_management_system/core/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- ADD THIS IMPORT

class DioClient {
  DioClient._();

  static final DioClient instance = DioClient._();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Dio get dio => _dio;

  // --- THIS IS THE CRITICAL UPDATE ---
  void setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // <-- Make this function async
          // This function is called before a request is sent.

          // Get the saved JWT token from SharedPreferences.
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('jwt_token');

          // If a token exists, add it to the Authorization header.
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          print('REQUEST[${options.method}] => PATH: ${options.uri}');
          return handler.next(options); // Continue with the request.
        },
        onResponse: (response, handler) {
          print('RESPONSE[${response.statusCode}] => DATA: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print('ERROR[${e.response?.statusCode}] => MESSAGE: ${e.message}');
          return handler.next(e);
        },
      ),
    );
  }
}
