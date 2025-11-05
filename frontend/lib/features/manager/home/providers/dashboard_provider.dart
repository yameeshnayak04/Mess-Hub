// lib/features/manager/dashboard/providers/dashboard_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../../../../models/dashboard_stats.dart';
import '../repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(dioClientProvider)),
);

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
    state = const AsyncValue.loading();
    try {
      final stats = await _repository.getDashboardStats();
      state = AsyncValue.data(stats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async => loadStats();

  // Drill-down
  Future<List<Map<String, dynamic>>> getMembersEating() =>
      _repository.getMembersEating();
  Future<List<Map<String, dynamic>>> getMembersOnLeave() =>
      _repository.getMembersOnLeave();
  Future<List<Map<String, dynamic>>> getMembersSkipped() =>
      _repository.getMembersSkipped();
  Future<List<Map<String, dynamic>>> getMembersRemaining() =>
      _repository.getMembersRemaining();
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
