import '../../../../core/api/dio_client.dart';
import '../../../../models/mess.dart';
import '../../../../models/menu.dart';
import '../../../../models/review.dart';

class MessDetailsRepository {
  final DioClient _dioClient;

  MessDetailsRepository(this._dioClient);

  Future<Mess> getMessDetails(String messId) async {
    final response = await _dioClient.get('/mess/$messId');
    return Mess.fromJson(response.data['data']);
  }

  Future<List<Menu>> getMenu(String messId,
      {DateTime? startDate, DateTime? endDate}) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }

    final response = await _dioClient.get(
      '/menu/$messId',
      queryParameters: queryParams,
    );
    final data = response.data['data'] as List;
    return data.map((json) => Menu.fromJson(json)).toList();
  }

  Future<List<Review>> getReviews(String messId,
      {int page = 1, int limit = 10}) async {
    final response = await _dioClient.get(
      '/reviews/$messId',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data['data'] as List;
    return data.map((json) => Review.fromJson(json)).toList();
  }

  Future<void> addReview(String messId, int rating, String? comment) async {
    await _dioClient.post(
      '/reviews/$messId',
      data: {
        'rating': rating,
        if (comment != null) 'comment': comment,
      },
    );
  }

  Future<void> joinMess(String messId, String planName) async {
    await _dioClient.post(
      '/membership/join/$messId',
      data: {'planName': planName},
    );
  }
}
