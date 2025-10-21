// lib/features/customer_dashboard/presentation/providers/customer_dashboard_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/core/api/dio_client.dart';
import 'package:mess_management_system/features/customer_dashboard/data/datasources/customer_remote_datasource.dart';
import 'package:mess_management_system/features/customer_dashboard/data/repositories/customer_repository_impl.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/invoice.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/attendance_day.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/meal_timing.dart';

// State classes
class CustomerDashboardState {
  final bool isLoading;
  final String? error;
  final List<Membership> memberships;
  final Membership? selectedMembership;
  final Map<String, dynamic>? todayMenu;
  final List<AttendanceDay> attendance;
  final List<Invoice> invoices;
  final Map<String, MealTiming> mealTimings;

  CustomerDashboardState({
    this.isLoading = false,
    this.error,
    this.memberships = const [],
    this.selectedMembership,
    this.todayMenu,
    this.attendance = const [],
    this.invoices = const [],
    this.mealTimings = const {},
  });

  CustomerDashboardState copyWith({
    bool? isLoading,
    String? error,
    List<Membership>? memberships,
    Membership? selectedMembership,
    Map<String, dynamic>? todayMenu,
    List<AttendanceDay>? attendance,
    List<Invoice>? invoices,
    Map<String, MealTiming>? mealTimings,
  }) {
    return CustomerDashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      memberships: memberships ?? this.memberships,
      selectedMembership: selectedMembership ?? this.selectedMembership,
      todayMenu: todayMenu ?? this.todayMenu,
      attendance: attendance ?? this.attendance,
      invoices: invoices ?? this.invoices,
      mealTimings: mealTimings ?? this.mealTimings,
    );
  }
}

// Provider
class CustomerDashboardNotifier extends StateNotifier<CustomerDashboardState> {
  final CustomerRepositoryImpl _repository;

  CustomerDashboardNotifier(this._repository) : super(CustomerDashboardState());

  // Load all memberships
  Future<void> loadMemberships() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final memberships = await _repository.getMyMemberships();
      state = state.copyWith(
        isLoading: false,
        memberships: memberships,
        selectedMembership: memberships.isNotEmpty ? memberships.first : null,
      );

      // Auto-load data for first active membership
      if (memberships.isNotEmpty && memberships.first.isActive) {
        await loadTodayMenu(memberships.first.id);
        await loadMealTimings(memberships.first.messId);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Select a specific membership
  Future<void> selectMembership(Membership membership) async {
    state = state.copyWith(selectedMembership: membership);
    if (membership.isActive) {
      await loadTodayMenu(membership.id);
      await loadMealTimings(membership.messId);
    }
  }

  // Load today's menu
  Future<void> loadTodayMenu(String membershipId) async {
    try {
      final menu = await _repository.getTodayMenu(membershipId);
      state = state.copyWith(todayMenu: menu);
    } catch (e) {
      print('Error loading today\'s menu: $e');
    }
  }

  // Load meal timings
  Future<void> loadMealTimings(String messId) async {
    try {
      final timings = await _repository.getMealTimings(messId);
      final mealTimings = <String, MealTiming>{};

      if (timings['lunch'] != null) {
        mealTimings['Lunch'] = MealTiming(
          type: 'Lunch',
          startTime: timings['lunch']['start'],
          endTime: timings['lunch']['end'],
        );
      }

      if (timings['dinner'] != null) {
        mealTimings['Dinner'] = MealTiming(
          type: 'Dinner',
          startTime: timings['dinner']['start'],
          endTime: timings['dinner']['end'],
        );
      }

      state = state.copyWith(mealTimings: mealTimings);
    } catch (e) {
      print('Error loading meal timings: $e');
    }
  }

  // Toggle meal skip
  Future<void> toggleMealSkip(String mealType) async {
    if (state.selectedMembership == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.toggleMealSkip(state.selectedMembership!.id, mealType);
      state = state.copyWith(isLoading: false);
      // Refresh today's menu to update skip status
      await loadTodayMenu(state.selectedMembership!.id);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Load attendance for a month
  Future<void> loadAttendance(int year, int month) async {
    if (state.selectedMembership == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final attendance = await _repository.getAttendance(
        state.selectedMembership!.id,
        year,
        month,
      );
      state = state.copyWith(isLoading: false, attendance: attendance);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Mark leave
  Future<void> markLeave(
      DateTime startDate, DateTime endDate, String reason) async {
    if (state.selectedMembership == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.markLeave(
        state.selectedMembership!.id,
        startDate,
        endDate,
        reason,
      );
      state = state.copyWith(isLoading: false);
      // Refresh attendance
      await loadAttendance(DateTime.now().year, DateTime.now().month);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Load invoices
  Future<void> loadInvoices() async {
    if (state.selectedMembership == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final invoices =
          await _repository.getMyInvoices(state.selectedMembership!.id);
      state = state.copyWith(isLoading: false, invoices: invoices);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Notify payment
  Future<void> notifyPayment(String invoiceId, String screenshotPath) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.notifyPayment(invoiceId, screenshotPath);
      state = state.copyWith(isLoading: false);
      // Refresh invoices
      await loadInvoices();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Rate mess
  Future<void> rateMess(double rating, String? review) async {
    if (state.selectedMembership == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.rateMess(
        state.selectedMembership!.messId,
        rating,
        review,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Leave membership
  Future<void> leaveMembership() async {
    if (state.selectedMembership == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.leaveMembership(state.selectedMembership!.id);
      state = state.copyWith(isLoading: false);
      // Refresh memberships
      await loadMemberships();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Provider instance
final customerDashboardProvider =
    StateNotifierProvider<CustomerDashboardNotifier, CustomerDashboardState>(
        (ref) {
  final dataSource = CustomerRemoteDataSourceImpl();
  final repository = CustomerRepositoryImpl(remoteDataSource: dataSource);
  return CustomerDashboardNotifier(repository);
});
