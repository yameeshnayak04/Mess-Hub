import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../../../../models/dashboard_stats.dart';
import '../repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioClientProvider));
});

final dashboardStatsProvider =
    StateNotifierProvider<DashboardStatsNotifier, AsyncValue<DashboardStats>>(
        (ref) {
  return DashboardStatsNotifier(ref.watch(dashboardRepositoryProvider));
});

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
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await loadStats();
  }

  Future<List<dynamic>> getMembersEating() async {
    return await _repository.getMembersEating();
  }

  Future<List<dynamic>> getMembersOnLeave() async {
    return await _repository.getMembersOnLeave();
  }

  Future<List<dynamic>> getMembersSkipped() async {
    return await _repository.getMembersSkipped();
  }
}
