// lib/features/auth/data/datasources/auth_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:mess_management_system/core/api/dio_client.dart';

class AuthRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  // Send registration OTP with optional PIN (required for customers)
  Future<void> sendRegistrationOtp(
      String name, String phone, String role, String? pin) async {
    try {
      final data = {'name': name, 'phone': phone, 'role': role};
      // Include PIN only if provided (for customers)
      if (pin != null && pin.isNotEmpty) {
        data['pin'] = pin;
      }
      await _dio.post('/auth/register/send-otp', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to send OTP');
    }
  }

  Future<Map<String, dynamic>> verifyRegistrationOtp(
      String phone, String otp) async {
    try {
      final response = await _dio.post(
        '/auth/register/verify-otp',
        data: {'phone': phone, 'otp': otp},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to verify OTP');
    }
  }

  Future<void> sendLoginOtp(String phone) async {
    try {
      await _dio.post('/auth/login/send-otp', data: {'phone': phone});
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to send OTP');
    }
  }

  Future<Map<String, dynamic>> verifyLoginOtp(String phone, String otp) async {
    try {
      final response = await _dio.post(
        '/auth/login/verify-otp',
        data: {'phone': phone, 'otp': otp},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to verify OTP');
    }
  }
}
