// lib/features/customer/membership/repositories/reviews_repository.dart
import '../../../../core/api/dio_client.dart';
import '../../../../models/review.dart';

/// A page of reviews plus the mess's overall average, which the backend keeps
/// denormalised and returns in `meta`.
class ReviewPage {
  final List<Review> reviews;
  final double averageRating;
  final int total;

  ReviewPage({
    required this.reviews,
    required this.averageRating,
    required this.total,
  });
}

class ReviewsRepository {
  final DioClient _dio;
  ReviewsRepository(this._dio);

  /// The current customer's own review, or null if they have not left one.
  /// Note the path is `/mine`, not the old `/me`.
  Future<Review?> getMyReview(String messId) async {
    try {
      final res = await _dio.get('/reviews/$messId/mine');
      final data = DioClient.unwrap(res);
      if (data == null) return null;
      return Review.fromJson(Map<String, dynamic>.from(data as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  /// Writes or edits in one call - a customer has at most one review per
  /// mess, so there is no separate "add" and "update".
  Future<Review> upsertReview({
    required String messId,
    required int rating,
    String? comment,
  }) async {
    try {
      final res = await _dio.put('/reviews/$messId', data: {
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      });
      return Review.fromJson(
          Map<String, dynamic>.from(DioClient.unwrap(res) as Map));
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }

  Future<ReviewPage> getReviews(
    String messId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final res = await _dio.get(
        '/reviews/$messId',
        queryParameters: {'page': page, 'limit': limit},
      );
      final result = DioClient.unwrapWithMeta(res);
      final reviews = (result.data as List)
          .whereType<Map>()
          .map((e) => Review.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final meta = result.meta ?? const <String, dynamic>{};
      return ReviewPage(
        reviews: reviews,
        averageRating: (meta['averageRating'] as num?)?.toDouble() ?? 0,
        total: (meta['total'] as num?)?.toInt() ?? reviews.length,
      );
    } catch (error) {
      throw DioClient.asApiException(error);
    }
  }
}
