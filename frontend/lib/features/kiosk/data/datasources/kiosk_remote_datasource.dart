// lib/features/kiosk/data/datasources/kiosk_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:mess_management_system/core/api/dio_client.dart';
import 'package:mess_management_system/features/kiosk/data/models/kiosk_member_model.dart';

abstract class KioskRemoteDataSource {
  Future<List<KioskMember>> getActiveMembers(String messId);
  Future<void> logMonthlyMeal(
      String messId, String customerId, String mealType, String pin);
  Future<void> logDailyMeal(String messId, String mealType);
}

class KioskRemoteDataSourceImpl implements KioskRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  @override
  Future<List<KioskMember>> getActiveMembers(String messId) async {
    try {
      final res = await _dio.get('/kiosk/messes/$messId/active-members');
      final data = res.data;
      final List raw = data is List
          ? data
          : (data is Map && data['members'] is List)
              ? data['members'] as List
              : <dynamic>[];
      return raw
          .map((e) => KioskMember.fromJson((e ?? {}) as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message']?.toString() ??
          'Failed to fetch active members');
    } catch (_) {
      throw Exception('Failed to parse active members');
    }
  }

  @override
  Future<void> logMonthlyMeal(
      String messId, String customerId, String mealType, String pin) async {
    try {
      await _dio.post('/kiosk/messes/$messId/log-monthly', data: {
        'customerId': customerId,
        'mealType': mealType,
        'pin': pin,
      });
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message']?.toString() ??
          'Failed to log monthly meal');
    }
  }

  @override
  Future<void> logDailyMeal(String messId, String mealType) async {
    try {
      await _dio.post('/kiosk/messes/$messId/log-daily',
          data: {'mealType': mealType});
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message']?.toString() ??
          'Failed to log daily meal');
    }
  }
}
