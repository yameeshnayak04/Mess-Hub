// This file contains the state management logic for the manager's dashboard.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/manager_dashboard/data/datasources/manager_remote_datasource.dart';
import 'package:mess_management_system/features/manager_dashboard/data/repositories/manager_repository_impl.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/dashboard_stats.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/repositories/manager_repository.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/usecases/get_dashboard_stats.dart';

// Part 1: Define the State
// This class holds all the data for the manager dashboard UI.
class ManagerDashboardState {
  final bool isLoading;
  final String? error;
  final DashboardStats? stats;

  const ManagerDashboardState({
    this.isLoading = false,
    this.error,
    this.stats,
  });

  // copyWith method for easily creating new state objects.
  ManagerDashboardState copyWith({
    bool? isLoading,
    String? error,
    DashboardStats? stats,
  }) {
    return ManagerDashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // Clear old errors on new state changes
      stats: stats ?? this.stats,
    );
  }
}

// Part 2: Define the Notifier
// This class contains the logic to fetch data and manage the state.
class ManagerDashboardNotifier extends StateNotifier<ManagerDashboardState> {
  final GetDashboardStats _getDashboardStats;

  ManagerDashboardNotifier(this._getDashboardStats)
      : super(const ManagerDashboardState());

  // Method to fetch the live dashboard stats from the backend.
  Future<void> fetchDashboardStats() async {
    // Set the state to loading.
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Call the use case to get the data.
      final stats = await _getDashboardStats();
      // If successful, update the state with the new data.
      state = state.copyWith(isLoading: false, stats: stats);
    } catch (e) {
      // If an error occurs, update the state with the error message.
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Part 3: Define the Providers (Dependency Injection)

// Provider for the ManagerRemoteDataSource
final managerRemoteDataSourceProvider =
    Provider<ManagerRemoteDataSource>((ref) {
  return ManagerRemoteDataSourceImpl();
});

// Provider for the ManagerRepository
final managerRepositoryProvider = Provider<ManagerRepository>((ref) {
  return ManagerRepositoryImpl(
      remoteDataSource: ref.watch(managerRemoteDataSourceProvider));
});

// Provider for the GetDashboardStats use case
final getDashboardStatsProvider = Provider<GetDashboardStats>((ref) {
  return GetDashboardStats(ref.watch(managerRepositoryProvider));
});

// The main StateNotifierProvider that the UI will interact with.
final managerDashboardProvider =
    StateNotifierProvider<ManagerDashboardNotifier, ManagerDashboardState>(
        (ref) {
  return ManagerDashboardNotifier(ref.watch(getDashboardStatsProvider));
});
