// lib/features/customer/mess_details/providers/mess_details_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_app/core/api/dio_client_provider.dart';
import '../../../../models/mess.dart';
import '../../../../models/review.dart'; // Assuming you have a Review model
import '../repositories/mess_details_repository.dart'; // Create this repository
import '../../discover/repositories/discover_repository.dart'; // For joinMess
import '../../discover/providers/discover_provider.dart'; // For discoverRepositoryProvider

// Provider for the new repository
final messDetailsRepositoryProvider = Provider<MessDetailsRepository>((ref) {
  // Assuming MessDetailsRepository uses dioClientProvider like others
  return MessDetailsRepository(ref.watch(dioClientProvider));
});

// State for Mess Details Screen
class MessDetailsScreenState {
  final AsyncValue<Mess> mess;
  final AsyncValue<List<Review>> reviews;
  final bool isJoining; // Loading state for join button
  final String? joinError; // Error message specifically for join action

  MessDetailsScreenState({
    this.mess = const AsyncValue.loading(),
    this.reviews = const AsyncValue.loading(),
    this.isJoining = false,
    this.joinError,
  });

  MessDetailsScreenState copyWith({
    AsyncValue<Mess>? mess,
    AsyncValue<List<Review>>? reviews,
    bool? isJoining,
    String? joinError,
    bool clearJoinError = false,
  }) {
    return MessDetailsScreenState(
      mess: mess ?? this.mess,
      reviews: reviews ?? this.reviews,
      isJoining: isJoining ?? this.isJoining,
      joinError: clearJoinError ? null : joinError ?? this.joinError,
    );
  }
}

// StateNotifier
class MessDetailsNotifier extends StateNotifier<MessDetailsScreenState> {
  final String messId;
  final MessDetailsRepository _detailsRepository;
  final DiscoverRepository
      _discoverRepository; // Use DiscoverRepository for joinMess

  MessDetailsNotifier(
      this.messId, this._detailsRepository, this._discoverRepository)
      : super(MessDetailsScreenState()) {
    _fetchDetails();
    _fetchReviews();
  }

  Future<void> _fetchDetails() async {
    state = state.copyWith(mess: const AsyncValue.loading());
    try {
      final messData = await _detailsRepository
          .getMessById(messId); // Use details repo method
      state = state.copyWith(mess: AsyncValue.data(messData));
    } catch (e, stack) {
      state = state.copyWith(mess: AsyncValue.error(e, stack));
    }
  }

  Future<void> _fetchReviews() async {
    state = state.copyWith(reviews: const AsyncValue.loading());
    try {
      final reviewData = await _detailsRepository
          .getReviews(messId); // Use details repo method
      state = state.copyWith(reviews: AsyncValue.data(reviewData));
    } catch (e, stack) {
      state = state.copyWith(reviews: AsyncValue.error(e, stack));
    }
  }

  Future<bool> joinMess(String planName) async {
    state = state.copyWith(isJoining: true, clearJoinError: true);
    try {
      await _discoverRepository.joinMess(messId, planName); // Call repository
      state = state.copyWith(isJoining: false);
      return true; // Indicate success
    } catch (e) {
      state = state.copyWith(isJoining: false, joinError: e.toString());
      return false; // Indicate failure
    }
  }

  void refresh() {
    _fetchDetails();
    _fetchReviews();
  }
}

// Provider definition
final messDetailsProvider = StateNotifierProvider.autoDispose
    .family<MessDetailsNotifier, MessDetailsScreenState, String>((ref, messId) {
  final detailsRepository = ref.watch(messDetailsRepositoryProvider);
  final discoverRepository =
      ref.watch(discoverRepositoryProvider); // Watch existing provider
  return MessDetailsNotifier(messId, detailsRepository, discoverRepository);
});
