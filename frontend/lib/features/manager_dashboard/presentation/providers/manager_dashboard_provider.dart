// lib/features/manager_dashboard/presentation/providers/manager_dashboard_provider.dart (COMPLETE FIX)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/manager_dashboard/data/datasources/manager_remote_datasource.dart';
import 'package:mess_management_system/features/manager_dashboard/data/repositories/manager_repository_impl.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/dashboard_stats.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/member.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/member_detail.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/payment_approval.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/mess_profile.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/repositories/manager_repository.dart';

// --- State Classes ---
class DashboardState {
  final bool isLoading;
  final String? error;
  final String? messId;
  final DashboardStats? stats;
  final List<Member> members;
  final List<PaymentApproval> paymentApprovals;
  final MessProfile? messProfile;

  const DashboardState({
    this.isLoading = false,
    this.error,
    this.messId,
    this.stats,
    this.members = const [],
    this.paymentApprovals = const [],
    this.messProfile,
  });

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    String? messId,
    DashboardStats? stats,
    List<Member>? members,
    List<PaymentApproval>? paymentApprovals,
    MessProfile? messProfile,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      messId: messId ?? this.messId,
      stats: stats ?? this.stats,
      members: members ?? this.members,
      paymentApprovals: paymentApprovals ?? this.paymentApprovals,
      messProfile: messProfile ?? this.messProfile,
    );
  }
}

// --- Notifier ---
class ManagerDashboardNotifier extends StateNotifier<DashboardState> {
  final ManagerRepository _repository;
  String? _currentMessId;

  ManagerDashboardNotifier(this._repository) : super(const DashboardState());

  // FIXED: Initialize dashboard by fetching mess first and extracting ID
  Future<void> initializeDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // First, get manager's mess
      final messProfile = await _repository.getMyMess();

      // CRITICAL FIX: Extract messId from the profile
      _currentMessId = messProfile.messId;

      print('DEBUG: Fetched mess with ID: $_currentMessId'); // Debug log

      // Update state with messId and profile
      state = state.copyWith(
        messId: _currentMessId,
        messProfile: messProfile,
      );

      // Then load all dashboard data using the actual messId
      final stats = await _repository.getDashboardStats();
      final members = await _repository.getMembers();
      final paymentApprovals = await _repository.getPaymentApprovals();

      state = state.copyWith(
        isLoading: false,
        stats: stats,
        members: members,
        paymentApprovals: paymentApprovals,
      );
    } catch (e) {
      print('DEBUG: Error initializing dashboard: $e'); // Debug log
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  void setMessId(String messId) {
    _currentMessId = messId;
    state = state.copyWith(messId: messId);
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    if (_currentMessId == null) {
      print('DEBUG: Cannot load dashboard - messId is null');
      return;
    }

    print('DEBUG: Loading dashboard for messId: $_currentMessId');
    state = state.copyWith(isLoading: true, error: null);
    try {
      final stats = await _repository.getDashboardStats();
      final members = await _repository.getMembers();
      final paymentApprovals = await _repository.getPaymentApprovals();

      state = state.copyWith(
        isLoading: false,
        stats: stats,
        members: members,
        paymentApprovals: paymentApprovals,
      );
    } catch (e) {
      print('DEBUG: Error loading dashboard: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<MemberDetail?> getMemberDetail(String membershipId) async {
    try {
      return await _repository.getMemberDetail(membershipId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> approvePayment(String invoiceId) async {
    try {
      await _repository.approvePayment(invoiceId);
      if (_currentMessId != null) {
        final updated = await _repository.getPaymentApprovals();
        state = state.copyWith(paymentApprovals: updated);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> rejectPayment(String invoiceId) async {
    try {
      await _repository.rejectPayment(invoiceId);
      if (_currentMessId != null) {
        final updated = await _repository.getPaymentApprovals();
        state = state.copyWith(paymentApprovals: updated);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> uploadTodayMenu(Map<String, dynamic> menuData) async {
    if (_currentMessId == null) return;
    try {
      await _repository.uploadTodayMenu(menuData);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<String> downloadInvoice(String invoiceId) async {
    try {
      return await _repository.downloadInvoice(invoiceId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

// --- Providers ---
final managerRemoteDataSourceProvider = Provider<ManagerRemoteDataSource>(
  (ref) => ManagerRemoteDataSource(),
);

final managerRepositoryProvider = Provider<ManagerRepository>(
  (ref) => ManagerRepositoryImpl(
    remoteDataSource: ref.watch(managerRemoteDataSourceProvider),
  ),
);

final managerDashboardProvider =
    StateNotifierProvider<ManagerDashboardNotifier, DashboardState>(
  (ref) => ManagerDashboardNotifier(ref.watch(managerRepositoryProvider)),
);
