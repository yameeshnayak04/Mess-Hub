// lib/features/manager/menu/repositories/manager_menu_repository.dart
import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';

class ManagerMenuRepository {
  final DioClient _dio;
  ManagerMenuRepository(this._dio);

  String _msg(Response res, String fallback) {
    final d = res.data;
    if (d is Map &&
        d['message'] is String &&
        (d['message'] as String).isNotEmpty) return d['message'];
    if (d is Map && d['error'] is String && (d['error'] as String).isNotEmpty)
      return d['error'];
    return fallback;
  }

  Future<String?> _getMyMessId() async {
    final res = await _dio.get('/mess/my-mess');
    if (res.statusCode == 200 && res.data is Map) {
      return ((res.data['data'] as Map?)?['_id'] as String?);
    }
    throw _msg(res, 'Failed to load mess');
  }

  Future<Map<String, dynamic>?> getMenuForDate(DateTime date) async {
    final messId = await _getMyMessId();
    if (messId == null) return null;
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final res = await _dio.get('/menu/$messId', queryParameters: {
      'startDate': '$y-$m-$d',
      // 'endDate': '$y-$m-$d', // optional if backend supports range
    });
    if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
      final list = (res.data['data'] as List);
      if (list.isEmpty) return null;
      final first = list.first;
      return (first is Map) ? Map<String, dynamic>.from(first) : null;
    }
    throw _msg(res, 'Failed to load menu');
  }

  Future<Map<String, dynamic>> setMenu({
    required DateTime date,
    required List<String> lunchItems,
    required List<String> dinnerItems,
  }) async {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final res = await _dio.post('/menu', data: {
      'date': '$y-$m-$d',
      'lunchItems': lunchItems,
      'dinnerItems': dinnerItems,
    });
    if (res.statusCode == 200 && res.data is Map) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    throw _msg(res, 'Failed to save menu');
  }
}
