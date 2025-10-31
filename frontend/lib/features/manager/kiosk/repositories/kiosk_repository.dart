// lib/features/manager/kiosk/repositories/kiosk_repository.dart
import '../../../../core/api/dio_client.dart';

class KioskRepository {
  final DioClient _dio;
  KioskRepository(this._dio);

  Future<Map<String, dynamic>?> getMyMess() async {
    final res = await _dio.get('/mess/my-mess');
    return res.data['data'] as Map<String, dynamic>?;
  }

  Future<List<dynamic>> getActiveMembers() async {
    final res = await _dio
        .get('/membership/mess', queryParameters: {'status': 'Active'});
    return (res.data['data'] as List);
  }

  Future<List<dynamic>> getMembersEatingNow() async {
    final res = await _dio.get('/mess/dashboard/members-eating');
    return (res.data['data'] as List);
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
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> markDaily({
    required String mealType, // Lunch | Dinner
  }) async {
    final res = await _dio
        .post('/attendance/kiosk/daily', data: {'mealType': mealType});
    return res.data as Map<String, dynamic>;
  }
}
