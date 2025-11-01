// lib/features/customer/home/providers/membership_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../../../../models/membership.dart';
import '../repositories/membership_repository.dart';

final membershipRepositoryProvider = Provider((ref) {
  return MembershipRepository(ref.watch(dioClientProvider));
});

// Auto-dispose to prevent stale data when customer shell is not visible
final membershipProvider = StateNotifierProvider.autoDispose<MembershipNotifier,
    AsyncValue<List<Membership>>>((ref) {
  return MembershipNotifier(ref.watch(membershipRepositoryProvider));
});

class MembershipNotifier extends StateNotifier<AsyncValue<List<Membership>>> {
  final MembershipRepository _repository;

  MembershipNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadMemberships();
  }

  Future<void> loadMemberships() async {
    state = const AsyncValue.loading();
    try {
      final base = await _repository.getMyMemberships();

      // Enrich mess ratings in parallel for memberships that have mess populated
      final futures = base.map((mem) async {
        if (mem.messObject == null) return mem;
        try {
          final rating = await _repository.getMessRating(mem.messObject!.id);
          final updatedMess = mem.messObject!.copyWith(
            averageRating: rating['averageRating'] as double?,
            reviewCount: rating['reviewCount'] as int?,
          );
          return mem.copyWith(mess: updatedMess);
        } catch (_) {
          return mem; // keep original if rating fetch fails
        }
      }).toList();

      final enriched = await Future.wait(futures);
      state = AsyncValue.data(enriched);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => loadMemberships();

  Future<void> leave(String membershipId) async {
    await _repository.leaveMembership(membershipId);
    await loadMemberships();
  }
}
