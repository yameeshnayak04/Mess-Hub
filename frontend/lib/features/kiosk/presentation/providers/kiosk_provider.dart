// This file contains the state management logic for the Kiosk.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/kiosk/data/datasources/kiosk_remote_datasource.dart';
import 'package:mess_management_system/features/kiosk/data/models/kiosk_member_model.dart';

// Part 1: Define the State
class KioskState {
  final bool isLoading;
  final String? error;
  final List<KioskMember> members;

  const KioskState({
    this.isLoading = false,
    this.error,
    this.members = const [],
  });

  KioskState copyWith({
    bool? isLoading,
    String? error,
    List<KioskMember>? members,
  }) {
    return KioskState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      members: members ?? this.members,
    );
  }
}

// Part 2: Define the Notifier
class KioskNotifier extends StateNotifier<KioskState> {
  final KioskRemoteDataSource _dataSource;

  KioskNotifier(this._dataSource) : super(const KioskState());

  Future<void> getActiveMembers(String messId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final members = await _dataSource.getActiveMembers(messId);
      state = state.copyWith(isLoading: false, members: members);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logMonthlyMeal(
      String messId, String customerId, String mealType) async {
    // We don't need a loading state for this, as it's a quick action.
    try {
      await _dataSource.logMonthlyMeal(messId, customerId, mealType);
      // After logging, remove the member from the list to show they have eaten.
      state = state.copyWith(
        members: state.members.where((m) => m.userId != customerId).toList(),
      );
    } catch (e) {
      // Re-throw the error to be shown in a SnackBar on the UI.
      rethrow;
    }
  }

  Future<void> logDailyMeal(String messId, String mealType) async {
    try {
      await _dataSource.logDailyMeal(messId, mealType);
    } catch (e) {
      rethrow;
    }
  }
}

// Part 3: Define the Providers
final kioskRemoteDataSourceProvider = Provider<KioskRemoteDataSource>((ref) {
  return KioskRemoteDataSourceImpl();
});

final kioskProvider = StateNotifierProvider<KioskNotifier, KioskState>((ref) {
  return KioskNotifier(ref.watch(kioskRemoteDataSourceProvider));
});
