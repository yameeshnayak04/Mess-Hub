import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dio_client.dart';
import 'auth_interceptor.dart';
import '../services/storage_service.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  dio.options.validateStatus = (status) => true;
  final storageService = ref.watch(storageServiceProvider);

  dio.interceptors.add(
    AuthInterceptor(
      storageService: storageService,
      onUnauthorized: () {
        // Don't call authProvider here - just clear storage
        storageService.deleteAll();
      },
    ),
  );

  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
  ));

  return dio;
});

final dioClientProvider = Provider<DioClient>((ref) {
  final dio = ref.watch(dioProvider);
  return DioClient(dio);
});
