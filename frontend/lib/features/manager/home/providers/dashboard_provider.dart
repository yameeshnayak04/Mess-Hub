// lib/features/manager/dashboard/providers/dashboard_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../../../../models/bill.dart';
import '../../../../models/dashboard_stats.dart';
import '../../../../models/membership.dart';
import '../../../../models/menu.dart';
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

  Future<List<DashboardMember>> getMembersEating(String meal) =>
      _repository.getMembersEating(meal: meal);

  Future<List<DashboardMember>> getMembersOnLeave(String meal) =>
      _repository.getMembersOnLeave(meal: meal);

  Future<List<DashboardMember>> getMembersSkipped(String meal) =>
      _repository.getMembersSkipped(meal: meal);

  Future<List<DashboardMember>> getMembersRemaining(String meal) =>
      _repository.getMembersRemaining(meal: meal);
}

// Lists for action center
final pendingApprovalsProvider =
    FutureProvider.autoDispose<List<Bill>>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getPendingApprovals();
});

final pendingJoinRequestsProvider =
    FutureProvider.autoDispose<List<Membership>>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getPendingJoinRequests();
});

// Today’s menu
final todaysMenuProvider = FutureProvider.autoDispose<Menu?>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getTodaysMenu();
});
