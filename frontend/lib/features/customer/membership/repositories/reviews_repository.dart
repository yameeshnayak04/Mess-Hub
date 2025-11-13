import 'package:dio/dio.dart';
import '../../../../core/api/dio_client.dart';

class ReviewsRepository {
  final DioClient _dio;
  ReviewsRepository(this._dio);

  Future<Map?> getMyReview(String messId) async {
    final res = await _dio.get('/reviews/$messId/me');
    if (res.statusCode == 200) {
      return (res.data is Map) ? (res.data['data'] as Map?) : null;
    }
    throw Exception('Failed to fetch review');
  }

  Future<Map> upsertReview({
    required String messId,
    required int rating,
    required String comment,
  }) async {
    final res = await _dio.put('/reviews/$messId', data: {
      'rating': rating,
      'comment': comment,
    });
    if (res.statusCode == 200 || res.statusCode == 201) {
      return (res.data as Map)['data'] as Map;
    }
    throw Exception(
        ((res.data as Map?)?['message'] as String?) ?? 'Failed to save review');
  }

  Future<List<Map>> getReviews(String messId,
      {int page = 1, int limit = 10}) async {
    final res = await _dio.get('/reviews/$messId',
        queryParameters: {'page': page, 'limit': limit});
    if (res.statusCode == 200) {
      final data = (res.data as Map)['data'] as List? ?? [];
      return data.cast<Map>();
    }
    throw Exception('Failed to load reviews');
  }
}
