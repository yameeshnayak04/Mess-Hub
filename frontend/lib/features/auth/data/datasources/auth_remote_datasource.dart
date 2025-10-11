// This file is responsible for making the actual API calls to the backend.

import 'package:dio/dio.dart';
import 'package:mess_management_system/core/api/dio_client.dart';

class AuthRemoteDataSource {
  // Get the singleton instance of our Dio client.
  final Dio _dio = DioClient.instance.dio;

  // Sends the registration OTP request to the server.
  Future<void> sendRegistrationOtp(
      String name, String phone, String role) async {
    try {
      await _dio.post(
        '/auth/register/send-otp', // Endpoint is appended to the baseUrl
        data: {'name': name, 'phone': phone, 'role': role},
      );
    } on DioException catch (e) {
      // Handle Dio-specific errors and re-throw a more user-friendly exception.
      throw Exception(e.response?.data['message'] ?? 'Failed to send OTP');
    }
  }

  // Verifies the registration OTP and returns the raw user data (Map).
  Future<Map<String, dynamic>> verifyRegistrationOtp(
      String phone, String otp) async {
    try {
      final response = await _dio.post(
        '/auth/register/verify-otp',
        data: {'phone': phone, 'otp': otp},
      );
      return response.data; // Return the JSON response body as a Map
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to verify OTP');
    }
  }

  // Sends the login OTP request.
  Future<void> sendLoginOtp(String phone) async {
    try {
      await _dio.post(
        '/auth/login/send-otp',
        data: {'phone': phone},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to send OTP');
    }
  }

  // Verifies the login OTP and returns the raw user data.
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
