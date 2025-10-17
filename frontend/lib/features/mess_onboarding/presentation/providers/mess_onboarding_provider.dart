// lib/features/mess_onboarding/presentation/providers/mess_onboarding_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/mess_onboarding/data/datasources/mess_onboarding_remote_datasource.dart';
import 'package:mess_management_system/features/mess_onboarding/data/repositories/mess_onboarding_repository_impl.dart';
import 'package:mess_management_system/features/mess_onboarding/domain/repositories/mess_onboarding_repository.dart';
import 'package:mess_management_system/features/mess_onboarding/domain/usecases/create_mess.dart';

// State class for the onboarding process
class MessOnboardingState {
  final bool isLoading;
  final String? error;
  const MessOnboardingState({this.isLoading = false, this.error});

  MessOnboardingState copyWith({bool? isLoading, String? error}) {
    return MessOnboardingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier class with the business logic
class MessOnboardingNotifier extends StateNotifier<MessOnboardingState> {
  final CreateMess _createMess;
  MessOnboardingNotifier(this._createMess) : super(const MessOnboardingState());

  Future<void> createMess(Map<String, dynamic> messData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _createMess(messData);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

// --- Dependency Injection Providers ---
final messOnboardingRemoteDataSourceProvider =
    Provider<MessOnboardingRemoteDataSource>(
        (ref) => MessOnboardingRemoteDataSourceImpl());
final messOnboardingRepositoryProvider = Provider<MessOnboardingRepository>(
    (ref) => MessOnboardingRepositoryImpl(
        remoteDataSource: ref.watch(messOnboardingRemoteDataSourceProvider)));
final createMessProvider = Provider<CreateMess>(
    (ref) => CreateMess(ref.watch(messOnboardingRepositoryProvider)));
final messOnboardingProvider =
    StateNotifierProvider<MessOnboardingNotifier, MessOnboardingState>(
        (ref) => MessOnboardingNotifier(ref.watch(createMessProvider)));
