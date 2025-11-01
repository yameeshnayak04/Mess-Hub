// lib/features/manager/kiosk/repositories/kiosk_repository.dart
import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';

class KioskRepository {
  final DioClient _dio;
  KioskRepository(this._dio);

  String _msg(Response res, String fallback) {
    final d = res.data;
    if (d is Map &&
        d['message'] is String &&
        (d['message'] as String).isNotEmpty) {
      return d['message'];
    }
    if (d is Map && d['error'] is String && (d['error'] as String).isNotEmpty) {
      return d['error'];
    }
    return fallback;
  }

  Future<Map<String, dynamic>?> getMyMess() async {
    final res = await _dio.get('/mess/my-mess');
    if (res.statusCode == 200 && res.data is Map) {
      return (res.data['data'] as Map?)?.cast<String, dynamic>();
    }
    throw _msg(res, 'Failed to load mess');
  }

  Future<List<Map<String, dynamic>>> getActiveMembers() async {
    final res = await _dio
        .get('/membership/mess', queryParameters: {'status': 'Active'});
    if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
      return (res.data['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    throw _msg(res, 'Failed to load members');
  }

  Future<List<Map<String, dynamic>>> getMembersEatingNow() async {
    final res = await _dio.get('/mess/dashboard/members-eating');
    if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
      return (res.data['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    throw _msg(res, 'Failed to load eating list');
  }

  Future<List<Map<String, dynamic>>> getMembersOnLeave() async {
    final res = await _dio.get('/mess/dashboard/members-on-leave');
    if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
      return (res.data['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    throw _msg(res, 'Failed to load leave list');
  }

  Future<List<Map<String, dynamic>>> getMembersSkipped() async {
    final res = await _dio.get('/mess/dashboard/members-skipped');
    if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
      return (res.data['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    throw _msg(res, 'Failed to load skipped list');
  }

  Future<Map<String, dynamic>> markMonthly({
    required String userId,
    required String kioskPin,
    required String mealType, // Lunch | Dinner
  }) async {
    final res = await _dio.post('/attendance/kiosk/mark', data: {
      'userId': userId,
      'kioskPin': kioskPin,
      'mealType': mealType,
    });
    if (res.statusCode == 200 && res.data is Map) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    throw _msg(res, 'Failed to mark attendance');
  }

  Future<Map<String, dynamic>> markDaily({required String mealType}) async {
    final res = await _dio
        .post('/attendance/kiosk/daily', data: {'mealType': mealType});
    if (res.statusCode == 200 && res.data is Map) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    throw _msg(res, 'Failed to log daily meal');
  }
}
