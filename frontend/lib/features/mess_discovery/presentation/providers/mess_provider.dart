// This file contains the state management logic for mess discovery using Riverpod.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/mess_discovery/data/datasources/mess_remote_datasource.dart';
import 'package:mess_management_system/features/mess_discovery/data/repositories/mess_repository_impl.dart';
import 'package:mess_management_system/features/mess_discovery/domain/entities/mess.dart';
import 'package:mess_management_system/features/mess_discovery/domain/repositories/mess_repository.dart';
import 'package:mess_management_system/features/mess_discovery/domain/usecases/get_mess_details.dart';
import 'package:mess_management_system/features/mess_discovery/domain/usecases/get_nearby_messes.dart';

// Part 1: Define the State
// This class represents the state of our mess discovery feature.
class MessDiscoveryState {
  final bool isLoading;
  final String? error;
  final List<Mess> messes; // List of nearby messes
  final Mess? selectedMess; // Details of a single selected mess

  const MessDiscoveryState({
    this.isLoading = false,
    this.error,
    this.messes = const [],
    this.selectedMess,
  });

  // copyWith method to easily create new state objects.
  MessDiscoveryState copyWith({
    bool? isLoading,
    String? error,
    List<Mess>? messes,
    Mess? selectedMess,
  }) {
    return MessDiscoveryState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      messes: messes ?? this.messes,
      selectedMess: selectedMess ?? this.selectedMess,
    );
  }
}

// Part 2: Define the Notifier
// This class contains the logic to fetch data and manage the state.
class MessDiscoveryNotifier extends StateNotifier<MessDiscoveryState> {
  final GetNearbyMesses _getNearbyMesses;
  final GetMessDetails _getMessDetails;

  MessDiscoveryNotifier(this._getNearbyMesses, this._getMessDetails)
      : super(const MessDiscoveryState());

  // Method to fetch nearby messes.
  Future<void> fetchNearbyMesses(double lat, double lng) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final messes = await _getNearbyMesses(lat, lng);
      state = state.copyWith(isLoading: false, messes: messes);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Method to fetch details of a single mess.
  Future<void> fetchMessDetails(String messId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final mess = await _getMessDetails(messId);
      state = state.copyWith(isLoading: false, selectedMess: mess);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Part 3: Define the Providers (Dependency Injection)

// Provider for the MessRemoteDataSource
final messRemoteDataSourceProvider = Provider<MessRemoteDataSource>((ref) {
  return MessRemoteDataSourceImpl();
});

// Provider for the MessRepository
final messRepositoryProvider = Provider<MessRepository>((ref) {
  return MessRepositoryImpl(
      remoteDataSource: ref.watch(messRemoteDataSourceProvider));
});

// Provider for the GetNearbyMesses use case
final getNearbyMessesProvider = Provider<GetNearbyMesses>((ref) {
  return GetNearbyMesses(ref.watch(messRepositoryProvider));
});

// Provider for the GetMessDetails use case
final getMessDetailsProvider = Provider<GetMessDetails>((ref) {
  return GetMessDetails(ref.watch(messRepositoryProvider));
});

// The main StateNotifierProvider that the UI will interact with.
final messDiscoveryProvider =
    StateNotifierProvider<MessDiscoveryNotifier, MessDiscoveryState>((ref) {
  final getNearbyMesses = ref.watch(getNearbyMessesProvider);
  final getMessDetails = ref.watch(getMessDetailsProvider);
  return MessDiscoveryNotifier(getNearbyMesses, getMessDetails);
});
