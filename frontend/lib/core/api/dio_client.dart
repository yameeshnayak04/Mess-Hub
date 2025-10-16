// This file sets up a centralized and powerful HTTP client using the Dio package.

import 'package:dio/dio.dart';
import 'package:mess_management_system/core/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import for token storage

class DioClient {
  DioClient._(); // Private constructor for Singleton pattern

  static final DioClient instance = DioClient._();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15), // Slightly increased timeout
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Dio get dio => _dio;

  // This function sets up the interceptor to automatically add the JWT token.
  void setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        // This function is called before every single request is sent.
        onRequest: (options, handler) async {
          // Get the saved JWT token from the device's local storage.
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('jwt_token');

          // If a token exists, add it to the 'Authorization' header.
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          print('REQUEST[${options.method}] => PATH: ${options.uri}');
          return handler.next(options); // Continue with the request.
        },
        onResponse: (response, handler) {
          print('RESPONSE[${response.statusCode}]');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print(
              'ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
          return handler.next(e);
        },
      ),
    );
  }
}
