// lib/features/mess_discovery/presentation/providers/mess_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/mess_discovery/data/datasources/mess_remote_datasource.dart';
import 'package:mess_management_system/features/mess_discovery/data/repositories/mess_repository_impl.dart';
import 'package:mess_management_system/features/mess_discovery/domain/entities/mess.dart';
import 'package:mess_management_system/features/mess_discovery/domain/repositories/mess_repository.dart';
import 'package:mess_management_system/features/mess_discovery/domain/usecases/get_mess_details.dart';
import 'package:mess_management_system/features/mess_discovery/domain/usecases/get_nearby_messes.dart';
import 'package:mess_management_system/features/mess_discovery/domain/usecases/join_mess.dart';

// --- State Class (with search logic) ---
class MessDiscoveryState {
  final bool isLoading;
  final String? error;
  final List<Mess> allMesses;
  final String searchQuery;
  final Mess? selectedMess;

  // A computed property (getter) to get the filtered list of messes.
  // The UI will use this to display the correct data.
  List<Mess> get filteredMesses {
    if (searchQuery.isEmpty) {
      return allMesses; // If search is empty, return all messes.
    } else {
      // Otherwise, filter the list based on the search query (name or address).
      return allMesses.where((mess) {
        final query = searchQuery.toLowerCase();
        return mess.name.toLowerCase().contains(query) ||
            mess.address.toLowerCase().contains(query);
      }).toList();
    }
  }

  const MessDiscoveryState(
      {this.isLoading = false,
      this.error,
      this.allMesses = const [],
      this.searchQuery = '',
      this.selectedMess});

  MessDiscoveryState copyWith(
      {bool? isLoading,
      String? error,
      List<Mess>? allMesses,
      String? searchQuery,
      Mess? selectedMess,
      bool clearSelectedMess = false}) {
    return MessDiscoveryState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      allMesses: allMesses ?? this.allMesses,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedMess:
          clearSelectedMess ? null : selectedMess ?? this.selectedMess,
    );
  }
}

// --- Notifier Class (with join and search methods) ---
class MessDiscoveryNotifier extends StateNotifier<MessDiscoveryState> {
  final GetNearbyMesses _getNearbyMesses;
  final GetMessDetails _getMessDetails;
  final JoinMess _joinMess;

  MessDiscoveryNotifier(
      this._getNearbyMesses, this._getMessDetails, this._joinMess)
      : super(const MessDiscoveryState());

  Future<void> fetchNearbyMesses({
    required double lat,
    required double lng,
    double radius = 10.0, // Default to 10km
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // We now pass the radius to the use case.
      final messes = await _getNearbyMesses(lat: lat, lng: lng, radius: radius);
      state = state.copyWith(isLoading: false, allMesses: messes);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // New method to update the search query in the state.
  void searchMesses(String query) {
    state = state.copyWith(searchQuery: query);
  }

  // New method to handle joining a mess.
  Future<void> joinMess(
      {required String messId, required String mealPlanId}) async {
    try {
      await _joinMess(messId: messId, mealPlanId: mealPlanId);
    } catch (e) {
      // Re-throw the error to be handled by the UI (e.g., show a SnackBar).
      rethrow;
    }
  }

  Future<void> fetchMessDetails(String messId) async {
    state =
        state.copyWith(isLoading: true, error: null, clearSelectedMess: true);
    try {
      final mess = await _getMessDetails(messId);
      state = state.copyWith(isLoading: false, selectedMess: mess);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// --- Providers (with new use case) ---
final messRemoteDataSourceProvider =
    Provider<MessRemoteDataSource>((ref) => MessRemoteDataSourceImpl());
final messRepositoryProvider = Provider<MessRepository>((ref) =>
    MessRepositoryImpl(
        remoteDataSource: ref.watch(messRemoteDataSourceProvider)));
final getNearbyMessesProvider = Provider<GetNearbyMesses>(
    (ref) => GetNearbyMesses(ref.watch(messRepositoryProvider)));
final getMessDetailsProvider = Provider<GetMessDetails>(
    (ref) => GetMessDetails(ref.watch(messRepositoryProvider)));
final joinMessProvider = Provider<JoinMess>((ref) =>
    JoinMess(ref.watch(messRepositoryProvider))); // <-- Add new provider

// The main provider now injects the JoinMess use case.
final messDiscoveryProvider =
    StateNotifierProvider<MessDiscoveryNotifier, MessDiscoveryState>((ref) {
  return MessDiscoveryNotifier(
    ref.watch(getNearbyMessesProvider),
    ref.watch(getMessDetailsProvider),
    ref.watch(joinMessProvider), // <-- Add new dependency
  );
});
