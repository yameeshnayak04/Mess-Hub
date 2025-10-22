// lib/features/kiosk/data/datasources/kiosk_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:mess_management_system/core/api/dio_client.dart';
import 'package:mess_management_system/features/kiosk/data/models/kiosk_member_model.dart';

class KioskRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  // Fetch active members not yet eaten for the specified meal; enrich with membershipId via manager members list.
  Future<List<KioskMemberModel>> getActiveMembers(
      String messId, String mealType) async {
    try {
      final resp = await _dio.get(
        '/kiosk/messes/$messId/active-members',
        queryParameters: {'mealType': mealType}, // Lunch | Dinner
      );
      final data = resp.data as Map<String, dynamic>;
      final members =
          (data['members'] as List? ?? []).cast<Map<String, dynamic>>();

      // Get membership mapping for this mess
      final memResp = await _dio.get('/manager/my-mess/members');
      final memRows =
          (memResp.data as List? ?? []).cast<Map<String, dynamic>>();
      final Map<String, String> customerToMembership = {};
      for (final m in memRows) {
        final customer = (m['customer'] ?? {}) as Map<String, dynamic>;
        final cid = (customer['_id'] ?? '').toString();
        final mid = (m['_id'] ?? '').toString();
        if (cid.isNotEmpty && mid.isNotEmpty) customerToMembership[cid] = mid;
      }

      // Enrich users with membershipId and status=available for display
      return members.map((u) {
        final cid = (u['_id'] ?? '').toString();
        final mid = customerToMembership[cid] ?? '';
        final json = {
          'membershipId': mid,
          '_id': cid,
          'name': u['name'],
          'phone': u['phone'],
          'photoUrl': u['photoUrl'],
          'status': 'available',
        };
        return KioskMemberModel.fromJson(json);
      }).toList();
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to fetch active members');
    }
  }

  // Log meal for a monthly member after PIN verification
  Future<void> logMonthlyMeal(
      String messId, String membershipId, String pin, String mealType) async {
    try {
      await _dio.post('/kiosk/messes/$messId/log-monthly', data: {
        'membershipId': membershipId,
        'pin': pin,
        'mealType': mealType, // Lunch | Dinner
      });
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to log meal');
    }
  }

  // Log a daily walk-in meal (only for serviceType=Both)
  Future<void> logDailyMeal(String messId, String mealType) async {
    try {
      await _dio.post('/kiosk/messes/$messId/log-daily', data: {
        'mealType': mealType, // Lunch | Dinner
      });
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to log daily meal');
    }
  }
}
