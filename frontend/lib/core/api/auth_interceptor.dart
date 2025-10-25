import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class AuthInterceptor extends Interceptor {
  final StorageService storageService;
  final void Function() onUnauthorized;

  AuthInterceptor({
    required this.storageService,
    required this.onUnauthorized,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Get token from secure storage
    final token = await storageService.read(StorageKeys.accessToken);

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401 Unauthorized
    if (err.response?.statusCode == 401) {
      onUnauthorized();
    }

    super.onError(err, handler);
  }
}
