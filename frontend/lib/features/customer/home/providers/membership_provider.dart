// lib/features/customer/home/providers/membership_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../../../../models/membership.dart';
import '../../../../models/mess.dart'; // Import Mess model
import '../repositories/membership_repository.dart';

final membershipRepositoryProvider = Provider<MembershipRepository>((ref) {
  return MembershipRepository(ref.watch(dioClientProvider));
});

// Use StateNotifierProvider.autoDispose for better state management
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
      // 1. Fetch the base list of memberships
      final memberships = await _repository.getMyMemberships();

      // 2. Enrich the list with rating data
      final List<Membership> membershipsWithRatings = [];
      for (final mem in memberships) {
        // Only enrich if mess data is populated as an object
        if (mem.messObject != null) {
          try {
            // Fetch rating data for this mess
            final ratingData =
                await _repository.getMessRating(mem.messObject!.id);

            // Create a new (cloned) Mess object with the rating data
            final updatedMess = mem.messObject!.copyWith(
              averageRating: ratingData['averageRating'] as double?,
              reviewCount: ratingData['reviewCount'] as int?,
            );

            // Create a new (cloned) Membership object with the updated Mess
            membershipsWithRatings.add(mem.copyWith(mess: updatedMess));
          } catch (e) {
            // If fetching rating fails, add the membership without rating
            print("Failed to get rating for ${mem.messObject!.messName}: $e");
            membershipsWithRatings.add(mem);
          }
        } else {
          // Add as-is if messObject is null (e.g., just a String ID)
          membershipsWithRatings.add(mem);
        }
      }

      // 3. Set the final enriched list as the state
      state = AsyncValue.data(membershipsWithRatings);
    } catch (e, stack) {
      // This will catch errors from getMyMemberships OR the repository fixes
      state = AsyncValue.error(e, stack);
    }
  }

  // Refresh simply calls loadMemberships again
  Future<void> refresh() => loadMemberships();
}
