// lib/features/mess_onboarding/data/datasources/mess_onboarding_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:mess_management_system/core/api/dio_client.dart';

abstract class MessOnboardingRemoteDataSource {
  Future<void> createMess(Map<String, dynamic> messData);
}

class MessOnboardingRemoteDataSourceImpl
    implements MessOnboardingRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  @override
  Future<void> createMess(Map<String, dynamic> messData) async {
    try {
      // Make a POST request to the protected '/messes' route.
      // The Dio interceptor will automatically add the manager's JWT token.
      await _dio.post('/messes', data: messData);
    } on DioException catch (e) {
      // Handle Dio-specific errors and throw a more user-friendly exception.
      throw Exception(e.response?.data['message'] ?? 'Failed to create mess');
    }
  }
}
