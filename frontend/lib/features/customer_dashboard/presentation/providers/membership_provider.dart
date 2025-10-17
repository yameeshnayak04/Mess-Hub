// lib/features/customer_dashboard/presentation/providers/membership_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- DOMAIN LAYER IMPORTS ---
import 'package:mess_management_system/features/customer_dashboard/domain/repositories/customer_repository.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/invoice.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/usecases/get_my_invoices.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/usecases/get_my_memberships.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/usecases/mark_leave.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/usecases/notify_payment.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/usecases/toggle_meal_skip.dart';

// --- DATA LAYER IMPORTS ---
import 'package:mess_management_system/features/customer_dashboard/data/datasources/customer_remote_datasource.dart';
import 'package:mess_management_system/features/customer_dashboard/data/repositories/customer_repository_impl.dart';

// Part 1: Define the State
// This class holds all the data needed for the customer dashboard UI.
class CustomerDashboardState {
  final bool isLoading;
  final String? error;
  final List<Membership> memberships;
  final List<Invoice> invoices;

  const CustomerDashboardState({
    this.isLoading = false,
    this.error,
    this.memberships = const [],
    this.invoices = const [],
  });

  // copyWith method for easily creating new, immutable state objects.
  CustomerDashboardState copyWith({
    bool? isLoading,
    String? error,
    List<Membership>? memberships,
    List<Invoice>? invoices,
  }) {
    return CustomerDashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // Clear old errors on new state changes
      memberships: memberships ?? this.memberships,
      invoices: invoices ?? this.invoices,
    );
  }
}

// Part 2: Define the Notifier
// This class contains all the business logic for the customer dashboard.
class CustomerDashboardNotifier extends StateNotifier<CustomerDashboardState> {
  final GetMyMemberships _getMyMemberships;
  final MarkLeave _markLeave;
  final GetMyInvoices _getMyInvoices;
  final NotifyPayment _notifyPayment;
  final ToggleMealSkip _toggleMealSkip;

  CustomerDashboardNotifier(this._getMyMemberships, this._markLeave,
      this._getMyInvoices, this._notifyPayment, this._toggleMealSkip)
      : super(const CustomerDashboardState());

  // Fetches all active memberships for the logged-in user.
  Future<void> fetchMyMemberships() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final memberships = await _getMyMemberships();
      state = state.copyWith(isLoading: false, memberships: memberships);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Marks a formal leave for a specific membership.
  Future<void> markLeave({
    required String membershipId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _markLeave(
        membershipId: membershipId,
        startDate: startDate,
        endDate: endDate,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow; // Re-throw so the UI can catch it and show a message.
    }
  }

  // Toggles the "Not Eating" status for a single meal.
  Future<void> toggleMealSkip({
    required String membershipId,
    required DateTime date,
    required String mealType,
  }) async {
    // This is a quick action, so we don't need a global loading state.
    try {
      await _toggleMealSkip(
        membershipId: membershipId,
        date: date,
        mealType: mealType,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Fetches all invoices for the logged-in user.
  Future<void> fetchMyInvoices() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final invoices = await _getMyInvoices();
      state = state.copyWith(isLoading: false, invoices: invoices);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Notifies the manager that a payment has been made.
  Future<void> notifyPayment({
    required String invoiceId,
    String? proofUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _notifyPayment(invoiceId: invoiceId, proofUrl: proofUrl);
      // After notifying, refresh the invoices to show the 'pending_approval' status.
      await fetchMyInvoices();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

// Part 3: Define the Providers (Dependency Injection)

final customerRemoteDataSourceProvider =
    Provider<CustomerRemoteDataSource>((ref) => CustomerRemoteDataSourceImpl());
final customerRepositoryProvider = Provider<CustomerRepository>((ref) =>
    CustomerRepositoryImpl(
        remoteDataSource: ref.watch(customerRemoteDataSourceProvider)));
final getMyMembershipsProvider = Provider<GetMyMemberships>(
    (ref) => GetMyMemberships(ref.watch(customerRepositoryProvider)));
final markLeaveProvider = Provider<MarkLeave>(
    (ref) => MarkLeave(ref.watch(customerRepositoryProvider)));
final getMyInvoicesProvider = Provider<GetMyInvoices>(
    (ref) => GetMyInvoices(ref.watch(customerRepositoryProvider)));
final notifyPaymentProvider = Provider<NotifyPayment>(
    (ref) => NotifyPayment(ref.watch(customerRepositoryProvider)));
final toggleMealSkipProvider = Provider<ToggleMealSkip>(
    (ref) => ToggleMealSkip(ref.watch(customerRepositoryProvider)));

final customerDashboardProvider =
    StateNotifierProvider<CustomerDashboardNotifier, CustomerDashboardState>(
        (ref) {
  return CustomerDashboardNotifier(
    ref.watch(getMyMembershipsProvider),
    ref.watch(markLeaveProvider),
    ref.watch(getMyInvoicesProvider),
    ref.watch(notifyPaymentProvider),
    ref.watch(toggleMealSkipProvider),
  );
});
