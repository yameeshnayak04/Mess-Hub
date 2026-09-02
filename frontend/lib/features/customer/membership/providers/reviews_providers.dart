import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../models/review.dart';
import '../repositories/reviews_repository.dart';
import '../../../../core/api/dio_client_provider.dart';

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  return ReviewsRepository(ref.read(dioClientProvider));
});

final myReviewProvider =
    FutureProvider.family<Review?, String>((ref, messId) async {
  return ref.read(reviewsRepositoryProvider).getMyReview(messId);
});
