// lib/features/manager/menu/repositories/manager_menu_repository.dart
import '../../../../core/api/dio_client.dart';

class ManagerMenuRepository {
  final DioClient _dio;
  ManagerMenuRepository(this._dio);

  Future<String?> _getMyMessId() async {
    final res = await _dio.get('/mess/my-mess');
    return (res.data['data'] as Map<String, dynamic>?)?['_id'] as String?;
  }

  Future<Map<String, dynamic>?> getMenuForDate(DateTime date) async {
    final messId = await _getMyMessId();
    if (messId == null) return null;
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final res = await _dio.get('/menu/$messId', queryParameters: {
      'startDate': '$y-$m-$d',
    });
    final list = (res.data['data'] as List);
    return list.isNotEmpty ? (list.first as Map<String, dynamic>) : null;
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
    return res.data as Map<String, dynamic>;
  }
}
