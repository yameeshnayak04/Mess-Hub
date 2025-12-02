// lib/features/manager/profile/providers/mess_profile_providers.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../repositories/mess_profile_repository.dart';
import '../../../auth/providers/auth_provider.dart';

// Repository
final messProfileRepositoryProvider = Provider((ref) {
  return MessProfileRepository(ref.watch(dioClientProvider));
});

// FIX: Depend on current auth to avoid stale data after account switch.
// Use autoDispose to ensure a fresh fetch whenever the screen is revisited.
final messProfileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  // Establish reactive dependency on auth (user/token)
  final auth = ref.watch(authProvider);
  final repo = ref.watch(messProfileRepositoryProvider);

  // Optional: short debounce if auth is still initializing
  if (auth == null) {
    // Return empty but allow screen to show a gentle loading state
    return Future.value(<String, dynamic>{});
  }

  final data = await repo.getMyMess();
  return data;
});

// Command provider unchanged
final messProfileUpdaterProvider = Provider<
    Future<Map<String, dynamic>> Function(Map<String, dynamic>,
        {MultipartFile? image})>((ref) {
  final repo = ref.read(messProfileRepositoryProvider);
  return (fields, {image}) =>
      repo.updateMyMess(fields: fields, imageFile: image);
});
