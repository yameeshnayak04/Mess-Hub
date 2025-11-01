// lib/features/customer/profile/providers/user_profile_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../repositories/user_profile_repository.dart';

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository(ref.watch(dioClientProvider));
});

// Simple command provider for updates
final userProfileUpdaterProvider = Provider((ref) {
  final repo = ref.read(userProfileRepositoryProvider);
  return ({String? name, String? pin}) =>
      repo.updateProfile(name: name, pin: pin);
});
