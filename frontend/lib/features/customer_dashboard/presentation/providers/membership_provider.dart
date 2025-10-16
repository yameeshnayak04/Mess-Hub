// This is the corrected and complete state management file with clean imports.

import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- DOMAIN LAYER IMPORTS ---
// Import the pure entities and the ABSTRACT repository (the "contract").
import 'package:mess_management_system/features/customer_dashboard/domain/repositories/customer_repository.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/invoice.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/usecases/get_billing_history.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/usecases/get_my_memberships.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/usecases/mark_leave.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/usecases/get_my_invoices.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/usecases/notify_payment.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/usecases/toggle_meal_skip.dart';

// --- DATA LAYER IMPORTS ---
// Import the CONCRETE implementations needed for dependency injection.
import 'package:mess_management_system/features/customer_dashboard/data/datasources/customer_remote_datasource.dart';
import 'package:mess_management_system/features/customer_dashboard/data/repositories/customer_repository_impl.dart';

// Part 1: Define the State
class CustomerDashboardState {
  final bool isLoading;
  final String? error;
  final List<Membership> memberships;
  final List<Invoice> invoices;
  const CustomerDashboardState(
      {this.isLoading = false,
      this.error,
      this.memberships = const [],
      this.invoices = const []});

  CustomerDashboardState copyWith(
      {bool? isLoading,
      String? error,
      List<Membership>? memberships,
      List<Invoice>? invoices}) {
    return CustomerDashboardState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        memberships: memberships ?? this.memberships,
        invoices: invoices ?? this.invoices);
  }
}

// Part 2: Define the Notifier
class CustomerDashboardNotifier extends StateNotifier<CustomerDashboardState> {
  final GetMyMemberships _getMyMemberships;
  final MarkLeave _markLeave;
  final GetBillingHistory _getBillingHistory;
  // Add other use cases
  final ToggleMealSkip _toggleMealSkip;
  final GetMyInvoices _getMyInvoices;
  final NotifyPayment _notifyPayment;

  CustomerDashboardNotifier(
      this._getMyMemberships,
      this._markLeave,
      this._getBillingHistory,
      this._toggleMealSkip,
      this._getMyInvoices,
      this._notifyPayment)
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

  Future<void> markLeave(
      {required String membershipId,
      required DateTime startDate,
      required DateTime endDate}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _markLeave(
          membershipId: membershipId, startDate: startDate, endDate: endDate);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  // Add methods for new use cases
  Future<void> fetchMyInvoices() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final invoices = await _getMyInvoices();
      state = state.copyWith(isLoading: false, invoices: invoices);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> notifyPayment(
      {required String invoiceId, String? proofUrl}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _notifyPayment(invoiceId: invoiceId, proofUrl: proofUrl);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> toggleMealSkip(
      {required String membershipId,
      required DateTime date,
      required String mealType}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _toggleMealSkip(
          membershipId: membershipId, date: date, mealType: mealType);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> fetchBillingHistory(String membershipId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final invoices = await _getBillingHistory(membershipId);
      state = state.copyWith(isLoading: false, invoices: invoices);
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
final getBillingHistoryProvider = Provider<GetBillingHistory>(
    (ref) => GetBillingHistory(ref.watch(customerRepositoryProvider)));
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
    ref.watch(getBillingHistoryProvider),
    ref.watch(toggleMealSkipProvider),
    ref.watch(getMyInvoicesProvider),
    ref.watch(notifyPaymentProvider),
  );
});
