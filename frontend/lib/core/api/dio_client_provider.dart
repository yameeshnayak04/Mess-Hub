import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dio_client.dart';
import 'auth_interceptor.dart';
import '../services/storage_service.dart';
import '../../features/auth/providers/auth_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  final storageService = ref.watch(storageServiceProvider);
  final authNotifier = ref.read(authProvider.notifier);

  dio.interceptors.add(
    AuthInterceptor(
      storageService: storageService,
      onUnauthorized: () {
        authNotifier.logout();
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
