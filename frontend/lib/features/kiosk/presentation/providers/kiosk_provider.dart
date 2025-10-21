// lib/features/kiosk/presentation/providers/kiosk_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/kiosk/data/datasources/kiosk_remote_datasource.dart';
import 'package:mess_management_system/features/kiosk/domain/entities/kiosk_member.dart';

// --- State ---
class KioskState {
  final bool isLoading;
  final String? error;
  final String? messId;
  final String currentMealType;
  final List<KioskMember> members;

  const KioskState({
    this.isLoading = false,
    this.error,
    this.messId,
    this.currentMealType = 'lunch',
    this.members = const [],
  });

  KioskState copyWith({
    bool? isLoading,
    String? error,
    String? messId,
    String? currentMealType,
    List<KioskMember>? members,
  }) {
    return KioskState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      messId: messId ?? this.messId,
      currentMealType: currentMealType ?? this.currentMealType,
      members: members ?? this.members,
    );
  }
}

// --- Notifier ---
class KioskNotifier extends StateNotifier<KioskState> {
  final KioskRemoteDataSource _dataSource;

  KioskNotifier(this._dataSource) : super(const KioskState());

  void setMessId(String messId) {
    state = state.copyWith(messId: messId);
    loadMembers();
  }

  void setMealType(String mealType) {
    state = state.copyWith(currentMealType: mealType);
    loadMembers();
  }

  Future<void> loadMembers() async {
    if (state.messId == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final members = await _dataSource.getActiveMembers(
        state.messId!,
        state.currentMealType,
      );
      state = state.copyWith(isLoading: false, members: members);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logMonthlyMeal(String membershipId, String pin) async {
    if (state.messId == null) return;
    try {
      await _dataSource.logMonthlyMeal(
        state.messId!,
        membershipId,
        pin,
        state.currentMealType,
      );
      // Reload members after successful logging
      await loadMembers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> logDailyMeal() async {
    if (state.messId == null) return;
    try {
      await _dataSource.logDailyMeal(state.messId!, state.currentMealType);
      // No need to reload members for daily users
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

// --- Providers ---
final kioskRemoteDataSourceProvider = Provider<KioskRemoteDataSource>(
  (ref) => KioskRemoteDataSource(),
);

final kioskProvider = StateNotifierProvider<KioskNotifier, KioskState>(
  (ref) => KioskNotifier(ref.watch(kioskRemoteDataSourceProvider)),
);
