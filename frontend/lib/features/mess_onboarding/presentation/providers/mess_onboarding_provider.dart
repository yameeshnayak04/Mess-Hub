// lib/features/mess_onboarding/presentation/providers/mess_onboarding_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/mess_onboarding/data/datasources/mess_onboarding_remote_datasource.dart';
import 'package:mess_management_system/features/mess_onboarding/data/repositories/mess_onboarding_repository_impl.dart';
import 'package:mess_management_system/features/mess_onboarding/domain/repositories/mess_onboarding_repository.dart';
import 'package:mess_management_system/features/mess_onboarding/domain/usecases/create_mess.dart';

// Part 1: Define the State
// This class holds the state for the mess creation API call.
class MessOnboardingState {
  final bool isLoading;
  final String? error;

  const MessOnboardingState({this.isLoading = false, this.error});

  // copyWith method for creating new state objects immutably.
  MessOnboardingState copyWith({bool? isLoading, String? error}) {
    return MessOnboardingState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // Clear old errors on new state changes
    );
  }
}

// Part 2: Define the Notifier
// This class contains the business logic to interact with the use case.
class MessOnboardingNotifier extends StateNotifier<MessOnboardingState> {
  final CreateMess _createMess;

  MessOnboardingNotifier(this._createMess) : super(const MessOnboardingState());

  // The main function to create the mess, called from the UI.
  Future<void> createMess(Map<String, dynamic> messData) async {
    // Set state to loading before making the API call.
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Execute the use case.
      await _createMess(messData);
      // If successful, reset state to not loading.
      state = state.copyWith(isLoading: false);
    } catch (e) {
      // If an error occurs, update the state with the error message.
      state = state.copyWith(isLoading: false, error: e.toString());
      // Re-throw the error so the UI can catch it and show a SnackBar.
      rethrow;
    }
  }
}

// Part 3: Define the Providers (for Dependency Injection)

// Provides the RemoteDataSource implementation.
final messOnboardingRemoteDataSourceProvider =
    Provider<MessOnboardingRemoteDataSource>((ref) {
  return MessOnboardingRemoteDataSourceImpl();
});

// Provides the Repository implementation, typed as the abstract class.
final messOnboardingRepositoryProvider =
    Provider<MessOnboardingRepository>((ref) {
  return MessOnboardingRepositoryImpl(
      remoteDataSource: ref.watch(messOnboardingRemoteDataSourceProvider));
});

// Provides the CreateMess use case.
final createMessProvider = Provider<CreateMess>((ref) {
  return CreateMess(ref.watch(messOnboardingRepositoryProvider));
});

// The main StateNotifierProvider that the UI will interact with.
final messOnboardingProvider =
    StateNotifierProvider<MessOnboardingNotifier, MessOnboardingState>((ref) {
  return MessOnboardingNotifier(ref.watch(createMessProvider));
});
