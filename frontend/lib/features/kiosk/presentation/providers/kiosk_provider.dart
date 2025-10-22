// lib/features/kiosk/presentation/providers/kiosk_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/kiosk/data/datasources/kiosk_remote_datasource.dart';
import 'package:mess_management_system/features/kiosk/data/models/kiosk_member_model.dart';

class KioskState {
  final String? messId;
  final String currentMealType; // Lunch | Dinner
  final List<KioskMemberModel> members;
  final bool isLoading;
  final String? error;

  const KioskState({
    this.messId,
    this.currentMealType = 'Lunch',
    this.members = const [],
    this.isLoading = false,
    this.error,
  });

  KioskState copyWith({
    String? messId,
    String? currentMealType,
    List<KioskMemberModel>? members,
    bool? isLoading,
    String? error,
  }) {
    return KioskState(
      messId: messId ?? this.messId,
      currentMealType: currentMealType ?? this.currentMealType,
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class KioskNotifier extends StateNotifier<KioskState> {
  final KioskRemoteDataSource remote;
  KioskNotifier(this.remote) : super(const KioskState());

  void setMessId(String messId) {
    state = state.copyWith(messId: messId);
  }

  void setMealType(String mealTypeLabel) {
    // Normalize labels from UI to backend format
    final mt = (mealTypeLabel.toLowerCase() == 'dinner') ? 'Dinner' : 'Lunch';
    state = state.copyWith(currentMealType: mt);
    // Do not auto-load here; caller can navigate then load
  }

  Future<void> loadMembers() async {
    if (state.messId == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final rows =
          await remote.getActiveMembers(state.messId!, state.currentMealType);
      state = state.copyWith(members: rows, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logMonthlyMeal(String membershipId, String pin) async {
    if (state.messId == null) throw Exception('Mess not selected');
    await remote.logMonthlyMeal(
        state.messId!, membershipId, pin, state.currentMealType);
    // Refresh grid after marking
    await loadMembers();
  }

  Future<void> logDailyMeal() async {
    if (state.messId == null) throw Exception('Mess not selected');
    await remote.logDailyMeal(state.messId!, state.currentMealType);
  }
}

final kioskProvider = StateNotifierProvider<KioskNotifier, KioskState>((ref) {
  return KioskNotifier(KioskRemoteDataSource());
});
