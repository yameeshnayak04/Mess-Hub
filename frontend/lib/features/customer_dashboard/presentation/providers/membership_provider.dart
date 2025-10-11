// This file contains the state management logic for the customer dashboard.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/customer_dashboard/data/datasources/customer_remote_datasource.dart';
import 'package:mess_management_system/features/customer_dashboard/data/repositories/customer_repository_impl.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/repositories/customer_repository.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/usecases/get_my_memberships.dart';

// Define the state class
class CustomerDashboardState {
  final bool isLoading;
  final String? error;
  final List<Membership> memberships;

  const CustomerDashboardState({
    this.isLoading = false,
    this.error,
    this.memberships = const [],
  });

  CustomerDashboardState copyWith({
    bool? isLoading,
    String? error,
    List<Membership>? memberships,
  }) {
    return CustomerDashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // Don't carry over old errors
      memberships: memberships ?? this.memberships,
    );
  }
}

// Define the Notifier
class CustomerDashboardNotifier extends StateNotifier<CustomerDashboardState> {
  final GetMyMemberships _getMyMemberships;

  CustomerDashboardNotifier(this._getMyMemberships)
      : super(const CustomerDashboardState());

  Future<void> fetchMyMemberships() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final memberships = await _getMyMemberships();
      state = state.copyWith(isLoading: false, memberships: memberships);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Define the Providers for Dependency Injection
final customerRemoteDataSourceProvider =
    Provider<CustomerRemoteDataSource>((ref) {
  return CustomerRemoteDataSourceImpl();
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepositoryImpl(
      remoteDataSource: ref.watch(customerRemoteDataSourceProvider));
});

final getMyMembershipsProvider = Provider<GetMyMemberships>((ref) {
  return GetMyMemberships(ref.watch(customerRepositoryProvider));
});

// The main StateNotifierProvider that the UI will interact with.
final customerDashboardProvider =
    StateNotifierProvider<CustomerDashboardNotifier, CustomerDashboardState>(
        (ref) {
  return CustomerDashboardNotifier(ref.watch(getMyMembershipsProvider));
});
