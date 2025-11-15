// lib/features/manager/dashboard/providers/dashboard_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../../../../models/dashboard_stats.dart';
import '../repositories/dashboard_repository.dart';

// lib/features/manager/dashboard/providers/dashboard_provider.dart

final dashboardRepositoryProvider =
    Provider((ref) => DashboardRepository(ref.watch(dioClientProvider)));

final dashboardStatsProvider =
    StateNotifierProvider<DashboardStatsNotifier, AsyncValue<DashboardStats>>(
  (ref) => DashboardStatsNotifier(ref.watch(dashboardRepositoryProvider)),
);

class DashboardStatsNotifier extends StateNotifier<AsyncValue<DashboardStats>> {
  final DashboardRepository _repository;

  DashboardStatsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadStats();
  }

  Future<void> loadStats() async {
    // show loading spinner
    state = const AsyncValue.loading();
    try {
      // fetch from backend
      final stats = await _repository.getDashboardStats();
      // push data into state
      state = AsyncValue.data(stats);
    } catch (e, st) {
      // show error in UI via ErrorView
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async => loadStats();

  Future<List<Map<String, dynamic>>> getMembersEating(String mealType) =>
      _repository.getMembersEating(mealType);

  Future<List<Map<String, dynamic>>> getMembersOnLeave(String mealType) =>
      _repository.getMembersOnLeave(mealType);

  Future<List<Map<String, dynamic>>> getMembersSkipped(String mealType) =>
      _repository.getMembersSkipped(mealType);

  Future<List<Map<String, dynamic>>> getMembersRemaining(String mealType) =>
      _repository.getMembersRemaining(mealType);
}

// Lists for action center
final pendingApprovalsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getPendingApprovals();
});

final pendingJoinRequestsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getPendingJoinRequests();
});

// Today’s menu
final todaysMenuProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getTodaysMenu();
});
