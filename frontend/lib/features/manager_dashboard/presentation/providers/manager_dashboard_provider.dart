// lib/features/manager_dashboard/presentation/providers/manager_dashboard_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/manager_dashboard/data/datasources/manager_remote_datasource.dart';
import 'package:mess_management_system/features/manager_dashboard/data/repositories/manager_repository_impl.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/dashboard_stats.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/manager_member.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/weekly_menu.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/mess_profile.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/mess_rating.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/today_attendance_member.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/repositories/manager_repository.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/invoice.dart';

class ManagerDashboardState {
  final bool isLoading;
  final String? error;

  final DashboardStats? stats;
  final WeeklyMenu? weeklyMenu;
  final List<ManagerMember> members;

  final List<Invoice> approvals;

  final List<TodayAttendanceMember> todayAttendance;
  final Map<String, Map<DateTime, bool>>
      memberAttendance; // memberId -> day map
  final Map<String, List<Invoice>> memberInvoices; // memberId -> invoices

  final MessProfile? myMessProfile;

  const ManagerDashboardState({
    this.isLoading = false,
    this.error,
    this.stats,
    this.weeklyMenu,
    this.members = const [],
    this.approvals = const [],
    this.todayAttendance = const [],
    this.memberAttendance = const {},
    this.memberInvoices = const {},
    this.myMessProfile,
  });

  ManagerDashboardState copyWith({
    bool? isLoading,
    String? error,
    DashboardStats? stats,
    WeeklyMenu? weeklyMenu,
    List<ManagerMember>? members,
    List<Invoice>? approvals,
    List<TodayAttendanceMember>? todayAttendance,
    Map<String, Map<DateTime, bool>>? memberAttendance,
    Map<String, List<Invoice>>? memberInvoices,
    MessProfile? myMessProfile,
  }) {
    return ManagerDashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stats: stats ?? this.stats,
      weeklyMenu: weeklyMenu ?? this.weeklyMenu,
      members: members ?? this.members,
      approvals: approvals ?? this.approvals,
      todayAttendance: todayAttendance ?? this.todayAttendance,
      memberAttendance: memberAttendance ?? this.memberAttendance,
      memberInvoices: memberInvoices ?? this.memberInvoices,
      myMessProfile: myMessProfile ?? this.myMessProfile,
    );
  }
}

class ManagerDashboardNotifier extends StateNotifier<ManagerDashboardState> {
  final ManagerRepository repo;
  ManagerDashboardNotifier(this.repo) : super(const ManagerDashboardState());

  // lib/features/manager_dashboard/presentation/providers/manager_dashboard_provider.dart
  Future<void> fetchHomeData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final stats = await repo.getDashboardStats();
      final members = await repo.getMessMembers();
      WeeklyMenu? menu;
      try {
        menu = await repo.getWeeklyMenu(); // may 404 if menu not created yet
      } catch (_) {
        menu = null; // swallow; UI will show “Not set”
      }
      state = state.copyWith(
        isLoading: false,
        stats: stats,
        weeklyMenu: menu,
        members: members,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchPaymentApprovals() async {
    try {
      final data = await repo.getPaymentApprovals();
      state = state.copyWith(approvals: data);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateInvoiceStatus(String id, String status,
      {String? reason}) async {
    try {
      await repo.updateInvoiceStatus(id, status, reason: reason);
      await fetchPaymentApprovals();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> fetchMessMembers() async {
    try {
      final data = await repo.getMessMembers();
      state = state.copyWith(members: data);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> fetchTodayAttendance() async {
    try {
      final list = await repo.getTodayAttendance();
      state = state.copyWith(todayAttendance: list);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> logMonthlyMealWithPin(String userId, String pin) async {
    try {
      final mealType = _currentMealTypeFromProfile();
      await repo.logMonthlyMealWithPin(userId, pin, mealType);
      await fetchTodayAttendance();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> logDailyMeal() async {
    try {
      final mealType = _currentMealTypeFromProfile();
      await repo.logDailyMeal(mealType);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  String _currentMealTypeFromProfile() {
    final p = state.myMessProfile;
    if (p == null) return DateTime.now().hour < 16 ? 'Lunch' : 'Dinner';
    // Prefer server timings where available
    bool inRange(String? start, String? end) {
      if (start == null || end == null) return false;
      final t = TimeOfDay.now();
      final s = _parseTime(start);
      final e = _parseTime(end);
      if (s == null || e == null) return false;
      final cur = Duration(hours: t.hour, minutes: t.minute);
      final ss = Duration(hours: s.hour, minutes: s.minute);
      final ee = Duration(hours: e.hour, minutes: e.minute);
      return cur >= ss && cur <= ee;
    }

    if (inRange(p.lunchStart, p.lunchEnd)) return 'Lunch';
    if (inRange(p.dinnerStart, p.dinnerEnd)) return 'Dinner';
    return DateTime.now().hour < 16 ? 'Lunch' : 'Dinner';
  }

  TimeOfDay? _parseTime(String s) {
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<MessProfile> fetchMyMessProfile() async {
    final p = await repo.getMyMessProfile();
    state = state.copyWith(myMessProfile: p);
    return p;
  }

  Future<void> updateMyMess(
      {String? name, String? managerContact, String? address}) async {
    await repo.updateMyMess(
        name: name, managerContact: managerContact, address: address);
    await fetchMyMessProfile();
  }

  Future<void> fetchMemberAttendance(String memberId, DateTime month) async {
    try {
      final map =
          await repo.getMemberAttendance(memberId, month.year, month.month);
      final newMap =
          Map<String, Map<DateTime, bool>>.from(state.memberAttendance);
      newMap[memberId] = map;
      state = state.copyWith(memberAttendance: newMap);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> fetchMemberInvoices(String memberId) async {
    try {
      final list = await repo.getMemberInvoices(memberId);
      final newMap = Map<String, List<Invoice>>.from(state.memberInvoices);
      newMap[memberId] = list;
      state = state.copyWith(memberInvoices: newMap);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // UI helpers
  List<String> namesForStat(String key) {
    // key: 'eaten', 'remaining', 'onLeave', etc. For demo, use todayAttendance.
    if (key == 'eaten') {
      return state.todayAttendance
          .where((m) => m.eaten)
          .map((m) => m.name)
          .toList();
    } else if (key == 'remaining') {
      return state.todayAttendance
          .where((m) => !m.eaten)
          .map((m) => m.name)
          .toList();
    }
    return [];
  }

  void openReviews(BuildContext context) {
    // Navigate to a reviews list if present in your app
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reviews screen coming soon')));
  }
}

// Providers
final _remoteProvider =
    Provider<ManagerRemoteDataSource>((ref) => ManagerRemoteDataSourceImpl());
final _repoProvider = Provider<ManagerRepository>(
    (ref) => ManagerRepositoryImpl(ref.read(_remoteProvider)));
final managerDashboardProvider =
    StateNotifierProvider<ManagerDashboardNotifier, ManagerDashboardState>(
        (ref) => ManagerDashboardNotifier(ref.read(_repoProvider)));
