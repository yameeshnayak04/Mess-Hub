// lib/features/discover/providers/discover_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../../../../models/mess.dart';
import '../repositories/discover_repository.dart';

final discoverRepositoryProvider = Provider<DiscoverRepository>((ref) {
  return DiscoverRepository(ref.watch(dioClientProvider));
});

final discoverProvider =
    StateNotifierProvider<DiscoverNotifier, AsyncValue<List<Mess>>>((ref) {
  return DiscoverNotifier(ref.watch(discoverRepositoryProvider));
});

class DiscoverNotifier extends StateNotifier<AsyncValue<List<Mess>>> {
  final DiscoverRepository _repository;
  String? _currentCuisine;
  String? _currentServiceType;
  String? _currentSearch;

  DiscoverNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadMesses();
  }

  Future<void> loadMesses({
    String? cuisine,
    String? serviceType,
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    _currentCuisine = cuisine;
    _currentServiceType = serviceType;
    _currentSearch = search;

    state = const AsyncValue.loading();
    try {
      final messes = await _repository.discoverMesses(
        cuisine: cuisine,
        serviceType: serviceType,
        search: search,
        page: page,
        limit: limit,
      );
      state = AsyncValue.data(messes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await loadMesses(
      cuisine: _currentCuisine,
      serviceType: _currentServiceType,
      search: _currentSearch,
    );
  }
}
