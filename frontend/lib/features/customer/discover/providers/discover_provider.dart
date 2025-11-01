// lib/features/discover/providers/discover_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../../../../models/mess.dart';
import '../repositories/discover_repository.dart';

final discoverRepositoryProvider =
    Provider((ref) => DiscoverRepository(ref.watch(dioClientProvider)));

final discoverProvider =
    StateNotifierProvider<DiscoverNotifier, AsyncValue<List<Mess>>>((ref) {
  return DiscoverNotifier(ref.watch(discoverRepositoryProvider));
});

class DiscoverNotifier extends StateNotifier<AsyncValue<List<Mess>>> {
  final DiscoverRepository _repository;
  String? _currentCuisine;
  String? _currentServiceType;
  String? _currentSearch;
  int _page = 1;
  final int _limit = 10;

  DiscoverNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadMesses();
  }

  Future<void> loadMesses(
      {String? cuisine, String? serviceType, String? search, int? page}) async {
    _currentCuisine = cuisine ?? _currentCuisine;
    _currentServiceType = serviceType ?? _currentServiceType;
    _currentSearch = search ?? _currentSearch;
    _page = page ?? 1;

    final previous = state;
    // Show lightweight busy state while keeping previous data
    state = previous.when(
      data: (d) => const AsyncValue.loading(),
      loading: () => const AsyncValue.loading(),
      error: (e, st) => const AsyncValue.loading(),
    );

    try {
      final messes = await _repository.discoverMesses(
        cuisine: _currentCuisine,
        serviceType: _currentServiceType,
        search: _currentSearch,
        page: _page,
        limit: _limit,
      );
      state = AsyncValue.data(messes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await loadMesses(page: 1);
  }
}
