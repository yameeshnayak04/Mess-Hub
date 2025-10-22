// lib/features/customer_dashboard/presentation/providers/customer_dashboard_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/customer_dashboard/data/datasources/customer_remote_datasource.dart';
import 'package:mess_management_system/features/customer_dashboard/data/repositories/customer_repository_impl.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/invoice.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/attendance_day.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/meal_timing.dart';

class CustomerDashboardState {
  final bool isLoading;
  final String? error;

  // Profile
  final Map<String, dynamic>? profile;

  // Core
  final List<Membership> memberships;
  final Membership? selectedMembership;

  // Home
  final Map<String, dynamic>? todayMenu;
  final Map<String, MealTiming> mealTimings;

  // Attendance
  final List<AttendanceDay> attendance;

  // Billing
  final List<Invoice> invoices;

  const CustomerDashboardState({
    this.isLoading = false,
    this.error,
    this.profile,
    this.memberships = const [],
    this.selectedMembership,
    this.todayMenu,
    this.mealTimings = const {},
    this.attendance = const [],
    this.invoices = const [],
  });

  CustomerDashboardState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? profile,
    List<Membership>? memberships,
    Membership? selectedMembership,
    Map<String, dynamic>? todayMenu,
    Map<String, MealTiming>? mealTimings,
    List<AttendanceDay>? attendance,
    List<Invoice>? invoices,
  }) {
    return CustomerDashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      profile: profile ?? this.profile,
      memberships: memberships ?? this.memberships,
      selectedMembership: selectedMembership ?? this.selectedMembership,
      todayMenu: todayMenu ?? this.todayMenu,
      mealTimings: mealTimings ?? this.mealTimings,
      attendance: attendance ?? this.attendance,
      invoices: invoices ?? this.invoices,
    );
  }
}

class CustomerDashboardNotifier extends StateNotifier<CustomerDashboardState> {
  final CustomerRepositoryImpl repo;
  CustomerDashboardNotifier(this.repo) : super(const CustomerDashboardState());

  // Bootstrap
  Future<void> initialize() async {
    await Future.wait([loadProfile(), loadMemberships()]);
  }

  // Profile
  Future<void> loadProfile() async {
    try {
      final me = await repo.getMyProfile();
      state = state.copyWith(profile: me);
    } catch (_) {}
  }

  Future<void> updateProfile(Map<String, dynamic> body) async {
    await repo.updateMyProfile(body);
    await loadProfile();
  }

  Future<void> updatePin(String pin) async {
    await repo.updatePin(pin);
  }

  // Memberships
  Future<void> loadMemberships() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final memberships = await repo.getMyMemberships();
      final sel = memberships.isNotEmpty ? memberships.first : null;
      state = state.copyWith(
        isLoading: false,
        memberships: memberships,
        selectedMembership: sel,
      );
      if (sel != null && sel.isActive) {
        await Future.wait([loadTodayMenu(sel.id), loadMealTimings(sel.messId)]);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> selectMembership(Membership m) async {
    state = state.copyWith(selectedMembership: m);
    if (m.isActive) {
      await Future.wait([loadTodayMenu(m.id), loadMealTimings(m.messId)]);
    } else {
      state = state.copyWith(todayMenu: null, mealTimings: const {});
    }
  }

  // Home
  Future<void> loadTodayMenu(String membershipId) async {
    try {
      final menu = await repo.getTodayMenu(membershipId);
      state = state.copyWith(todayMenu: menu);
    } catch (_) {}
  }

  Future<void> loadMealTimings(String messId) async {
    try {
      final map = await repo.getMealTimings(messId);
      final t = <String, MealTiming>{};
      if (map['lunch'] != null) {
        t['Lunch'] = MealTiming(
            type: 'Lunch',
            startTime: map['lunch']['start'],
            endTime: map['lunch']['end']);
      }
      if (map['dinner'] != null) {
        t['Dinner'] = MealTiming(
            type: 'Dinner',
            startTime: map['dinner']['start'],
            endTime: map['dinner']['end']);
      }
      state = state.copyWith(mealTimings: t);
    } catch (_) {}
  }

  Future<void> toggleMealSkip(String mealType) async {
    final sel = state.selectedMembership;
    if (sel == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await repo.toggleMealSkip(sel.id, mealType);
      state = state.copyWith(isLoading: false);
      await loadTodayMenu(sel.id);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Attendance
  Future<void> loadAttendance(int year, int month) async {
    final sel = state.selectedMembership;
    if (sel == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await repo.getAttendance(sel.id, year, month);
      state = state.copyWith(isLoading: false, attendance: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markLeave(DateTime start, DateTime end, String reason) async {
    final sel = state.selectedMembership;
    if (sel == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await repo.markLeave(sel.id, start, end, reason);
      state = state.copyWith(isLoading: false);
      await loadAttendance(DateTime.now().year, DateTime.now().month);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Billing
  Future<void> loadInvoices() async {
    final sel = state.selectedMembership;
    if (sel == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final inv = await repo.getMyInvoices(sel.id);
      state = state.copyWith(isLoading: false, invoices: inv);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> notifyPayment(String invoiceId, String screenshotPath) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await repo.notifyPayment(invoiceId, screenshotPath);
      state = state.copyWith(isLoading: false);
      await loadInvoices();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Ratings / leave membership
  Future<void> rateMess(double rating, String? review) async {
    final sel = state.selectedMembership;
    if (sel == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await repo.rateMess(sel.messId, rating, review);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> leaveMembership() async {
    final sel = state.selectedMembership;
    if (sel == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await repo.leaveMembership(sel.id);
      state = state.copyWith(isLoading: false);
      await loadMemberships();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final customerDashboardProvider =
    StateNotifierProvider<CustomerDashboardNotifier, CustomerDashboardState>(
        (ref) {
  final ds = CustomerRemoteDataSourceImpl();
  final repo = CustomerRepositoryImpl(remote: ds);
  final notifier = CustomerDashboardNotifier(repo);
  notifier.initialize();
  return notifier;
});
