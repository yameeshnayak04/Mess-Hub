// This file is responsible for making the actual API calls for the Kiosk.

import 'package:dio/dio.dart';
import 'package:mess_management_system/core/api/dio_client.dart';
import 'package:mess_management_system/features/kiosk/data/models/kiosk_member_model.dart';

abstract class KioskRemoteDataSource {
  Future<List<KioskMember>> getActiveMembers(String messId);
  Future<void> logMonthlyMeal(
      String messId, String customerId, String mealType);
  Future<void> logDailyMeal(String messId, String mealType);
}

class KioskRemoteDataSourceImpl implements KioskRemoteDataSource {
  // Get the singleton instance of our Dio client.
  final Dio _dio = DioClient.instance.dio;

  @override
  Future<List<KioskMember>> getActiveMembers(String messId) async {
    try {
      // Make a GET request to the public Kiosk route.
      final response = await _dio.get('/kiosk/messes/$messId/active-members');

      // Map the list of JSON objects from the response to a list of KioskMember models.
      final List<KioskMember> members = (response.data as List)
          .map((memberJson) => KioskMember.fromJson(memberJson))
          .toList();

      return members;
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch active members');
    }
  }

  @override
  Future<void> logMonthlyMeal(
      String messId, String customerId, String mealType) async {
    try {
      await _dio.post(
        '/kiosk/messes/$messId/log-monthly',
        data: {
          'customerId': customerId,
          'mealType': mealType,
        },
      );
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to log monthly meal');
    }
  }

  @override
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
