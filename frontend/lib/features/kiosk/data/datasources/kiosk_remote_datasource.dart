// lib/features/kiosk/data/datasources/kiosk_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:mess_management_system/core/api/dio_client.dart';
import 'package:mess_management_system/features/kiosk/data/models/kiosk_member_model.dart';

class KioskRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  /// Fetch active members who haven't eaten for the specified meal type today
  Future<List<KioskMemberModel>> getActiveMembers(
      String messId, String mealType) async {
    try {
      final response = await _dio.get(
        '/kiosk/messes/$messId/active-members',
        queryParameters: {'mealType': mealType},
      );
      final data = response.data as Map<String, dynamic>;
      final membersList = (data['members'] as List?) ?? [];
      return membersList
          .map((json) => KioskMemberModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch active members');
    }
  }

  /// Log meal for a monthly member after PIN verification
  Future<void> logMonthlyMeal(
      String messId, String membershipId, String pin, String mealType) async {
    try {
      await _dio.post(
        '/kiosk/messes/$messId/log-monthly',
        data: {
          'membershipId': membershipId,
          'pin': pin,
          'mealType': mealType,
        },
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to log meal');
    }
  }

  /// Log meal for a daily walk-in user (no PIN required)
  Future<void> logDailyMeal(String messId, String mealType) async {
    try {
      await _dio.post(
        '/kiosk/messes/$messId/log-daily',
        data: {'mealType': mealType},
      );
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to log daily meal');
    }
  }
}
