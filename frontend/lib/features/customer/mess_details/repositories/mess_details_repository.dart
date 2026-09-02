// lib/features/customer/mess_details/repositories/mess_details_repository.dart
import '../../../../core/api/dio_client.dart';
import '../../../../core/utils/json_parse.dart';
import '../../../../models/mess.dart';
import '../../../../models/menu.dart';
import '../../../../models/review.dart';

class MessDetailsRepository {
  final DioClient _dioClient;
  MessDetailsRepository(this._dioClient);

  /// The detail payload also carries `plans`, plus `liveStatus`/`currentMeal`
  /// so the screen can show whether the mess is serving right now.
  Future<Mess> getMessById(String messId) async {
    try {
      final res = await _dioClient.get('/messes/$messId');
      return Mess.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  Future<List<Review>> getReviews(
    String messId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final res = await _dioClient.get(
        '/reviews/$messId',
        queryParameters: {'page': page, 'limit': limit},
      );
      return (DioClient.unwrap(res) as List)
          .whereType<Map>()
          .map((e) => Review.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// Menus for a date range. With no dates the backend returns today's menu,
  /// which is what the details screen wants. Query params are `from`/`to`
  /// (they used to be `startDate`/`endDate`).
  Future<List<Menu>> getMenu({
    required String messId,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final res = await _dioClient.get(
        '/menus/$messId',
        queryParameters: {
          if (from != null) 'from': formatCalendarDate(from),
          if (to != null) 'to': formatCalendarDate(to),
        },
      );
      return (DioClient.unwrap(res) as List)
          .whereType<Map>()
          .map((e) => Menu.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }
}
