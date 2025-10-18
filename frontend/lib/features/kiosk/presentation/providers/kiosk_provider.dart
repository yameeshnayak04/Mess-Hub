// lib/features/kiosk/presentation/providers/kiosk_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/kiosk/data/datasources/kiosk_remote_datasource.dart';
import 'package:mess_management_system/features/kiosk/data/models/kiosk_member_model.dart';

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

class KioskNotifier extends StateNotifier<KioskState> {
  final KioskRemoteDataSource _dataSource;
  KioskNotifier(this._dataSource) : super(const KioskState());

  Future<void> getActiveMembers(String messId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final members = await _dataSource.getActiveMembers(messId);
      state = state.copyWith(isLoading: false, members: members);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          error: 'Could not load members. Please pull to refresh.');
    }
  }

  Future<void> logMonthlyMeal({
    required String messId,
    required String customerId,
    required String mealType,
    required String pin,
  }) async {
    await _dataSource.logMonthlyMeal(messId, customerId, mealType, pin);
    // Optimistic update: remove member from list
    state = state.copyWith(
      members: state.members.where((m) => m.userId != customerId).toList(),
    );
  }

  Future<void> logDailyMeal({
    required String messId,
    required String mealType,
  }) async {
    await _dataSource.logDailyMeal(messId, mealType);
  }
}

final kioskRemoteDataSourceProvider = Provider<KioskRemoteDataSource>((ref) {
  return KioskRemoteDataSourceImpl();
});

final kioskProvider = StateNotifierProvider<KioskNotifier, KioskState>((ref) {
  return KioskNotifier(ref.watch(kioskRemoteDataSourceProvider));
});
