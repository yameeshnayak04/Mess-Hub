// lib/features/customer/mess_details/providers/mess_details_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_app/core/api/dio_client_provider.dart';
import '../../../../models/mess.dart';
import '../../../../models/review.dart';
import '../repositories/mess_details_repository.dart';
import '../../discover/repositories/discover_repository.dart';
import '../../discover/providers/discover_provider.dart';

final messDetailsRepositoryProvider = Provider((ref) {
  return MessDetailsRepository(ref.watch(dioClientProvider));
});

class MessDetailsScreenState {
  final AsyncValue<Mess> mess;
  final AsyncValue<List<Review>> reviews;
  final AsyncValue<List<Map<String, dynamic>>>
      menu; // date, lunchItems, dinnerItems
  final bool isJoining;
  final String? joinError;
  final int reviewsPage;
  final bool reviewsHasMore;

  MessDetailsScreenState({
    this.mess = const AsyncValue.loading(),
    this.reviews = const AsyncValue.loading(),
    this.menu = const AsyncValue.loading(),
    this.isJoining = false,
    this.joinError,
    this.reviewsPage = 1,
    this.reviewsHasMore = true,
  });

  MessDetailsScreenState copyWith({
    AsyncValue<Mess>? mess,
    AsyncValue<List<Review>>? reviews,
    AsyncValue<List<Map<String, dynamic>>>? menu,
    bool? isJoining,
    String? joinError,
    bool clearJoinError = false,
    int? reviewsPage,
    bool? reviewsHasMore,
  }) {
    return MessDetailsScreenState(
      mess: mess ?? this.mess,
      reviews: reviews ?? this.reviews,
      menu: menu ?? this.menu,
      isJoining: isJoining ?? this.isJoining,
      joinError: clearJoinError ? null : (joinError ?? this.joinError),
      reviewsPage: reviewsPage ?? this.reviewsPage,
      reviewsHasMore: reviewsHasMore ?? this.reviewsHasMore,
    );
  }
}

class MessDetailsNotifier extends StateNotifier<MessDetailsScreenState> {
  final String messId;
  final MessDetailsRepository _detailsRepository;
  final DiscoverRepository _discoverRepository;

  MessDetailsNotifier(
      this.messId, this._detailsRepository, this._discoverRepository)
      : super(MessDetailsScreenState()) {
    refresh();
  }

  Future<void> _fetchDetails() async {
    state = state.copyWith(mess: const AsyncValue.loading());
    try {
      final messData = await _detailsRepository.getMessById(messId);
      state = state.copyWith(mess: AsyncValue.data(messData));
    } catch (e, st) {
      state = state.copyWith(mess: AsyncValue.error(e, st));
    }
  }

  Future<void> _fetchMenu() async {
    state = state.copyWith(menu: const AsyncValue.loading());
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 7)); // next 7 days
      final menus = await _detailsRepository.getMenu(
          messId: messId, startDate: start, endDate: end);
      state = state.copyWith(menu: AsyncValue.data(menus));
    } catch (e, st) {
      state = state.copyWith(menu: AsyncValue.error(e, st));
    }
  }

  Future<void> _fetchReviews(
      {int page = 1, int limit = 10, bool append = false}) async {
    if (!append) {
      state = state.copyWith(
          reviews: const AsyncValue.loading(),
          reviewsPage: 1,
          reviewsHasMore: true);
    }
    try {
      final data =
          await _detailsRepository.getReviews(messId, page: page, limit: limit);
      if (append) {
        final current = state.reviews.value ?? <Review>[];
        final merged = [...current, ...data];
        state = state.copyWith(
          reviews: AsyncValue.data(merged),
          reviewsPage: page,
          reviewsHasMore: data.length == limit,
        );
      } else {
        state = state.copyWith(
          reviews: AsyncValue.data(data),
          reviewsPage: 1,
          reviewsHasMore: data.length == limit,
        );
      }
    } catch (e, st) {
      state = state.copyWith(reviews: AsyncValue.error(e, st));
    }
  }

  Future<bool> loadMoreReviews() async {
    if (!state.reviewsHasMore || state.reviews.isLoading) return false;
    final next = state.reviewsPage + 1;
    await _fetchReviews(page: next, limit: 10, append: true);
    return state.reviewsHasMore;
  }

  Future<bool> joinMess(String planName) async {
    state = state.copyWith(isJoining: true, clearJoinError: true);
    try {
      await _discoverRepository.joinMess(messId, planName);
      state = state.copyWith(isJoining: false);
      return true;
    } catch (e) {
      state = state.copyWith(isJoining: false, joinError: e.toString());
      return false;
    }
  }

  void refresh() {
    _fetchDetails();
    _fetchMenu();
    _fetchReviews(page: 1, limit: 10, append: false);
  }
}

final messDetailsProvider = StateNotifierProvider.autoDispose
    .family<MessDetailsNotifier, MessDetailsScreenState, String>((ref, messId) {
  final detailsRepository = ref.watch(messDetailsRepositoryProvider);
  final discoverRepository = ref.watch(discoverRepositoryProvider);
  return MessDetailsNotifier(messId, detailsRepository, discoverRepository);
});
