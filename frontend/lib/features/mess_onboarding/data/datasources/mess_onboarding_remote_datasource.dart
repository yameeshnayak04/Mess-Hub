// lib/features/mess_onboarding/data/datasources/mess_onboarding_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:mess_management_system/core/api/dio_client.dart';

abstract class MessOnboardingRemoteDataSource {
  Future createMess(Map messData);
}

class MessOnboardingRemoteDataSourceImpl
    implements MessOnboardingRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  @override
  Future createMess(Map messData) async {
    try {
      await _dio.post('/messes', data: messData);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create mess');
    }
  }
}
