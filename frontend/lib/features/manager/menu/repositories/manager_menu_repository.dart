// lib/features/manager/menu/repositories/manager_menu_repository.dart
import '../../../../core/api/dio_client.dart';
import '../../../../core/utils/json_parse.dart';
import '../../../../models/menu.dart';

class ManagerMenuRepository {
  final DioClient _dio;
  ManagerMenuRepository(this._dio);

  String? _cachedMessId;

  /// The menu read route is public and takes a mess id, so we still need it.
  /// Cached because it never changes for a signed-in manager.
  Future<String> _messId() async {
    if (_cachedMessId != null) return _cachedMessId!;
    final res = await _dio.get('/messes/my-mess');
    final mess = Map<String, dynamic>.from(DioClient.unwrap(res) as Map);
    _cachedMessId = asId(mess['id']);
    return _cachedMessId!;
  }

  Future<Menu?> getMenuForDate(DateTime date) async {
    try {
      final day = formatCalendarDate(date);
      final res = await _dio.get(
        '/menus/${await _messId()}',
        queryParameters: {'from': day, 'to': day},
      );
      final list = (DioClient.unwrap(res) as List).whereType<Map>().toList();
      if (list.isEmpty) return null;
      return Menu.fromJson(Map<String, dynamic>.from(list.first));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// Writing a menu is now PUT /menus/my-mess with a `serviceDate` - the
  /// manager's own mess is implied, and re-posting a date replaces it.
  Future<Menu> setMenu({
    required DateTime date,
    required List<String> lunchItems,
    required List<String> dinnerItems,
  }) async {
    try {
      final res = await _dio.put('/menus/my-mess', data: {
        'serviceDate': formatCalendarDate(date),
        'lunchItems': lunchItems,
        'dinnerItems': dinnerItems,
      });
      return Menu.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }
}
