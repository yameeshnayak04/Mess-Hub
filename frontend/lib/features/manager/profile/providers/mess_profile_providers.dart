// lib/features/manager/profile/providers/mess_profile_providers.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../../../../models/mess.dart';
import '../repositories/mess_profile_repository.dart';
import '../../../auth/providers/auth_provider.dart';

// Repository
final messProfileRepositoryProvider = Provider((ref) {
  return MessProfileRepository(ref.watch(dioClientProvider));
});

// FIX: Depend on current auth to avoid stale data after account switch.
// Use autoDispose to ensure a fresh fetch whenever the screen is revisited.
final messProfileProvider = FutureProvider.autoDispose<Mess?>((ref) async {
  // Establish reactive dependency on auth (user/token)
  final auth = ref.watch(authProvider);
  final repo = ref.watch(messProfileRepositoryProvider);

  // Null, not an empty Mess: there is no such thing as a half-built mess, and
  // the screen shows a loading state for null.
  if (auth == null) return null;

  return repo.getMyMess();
});

// Command provider unchanged
final messProfileUpdaterProvider = Provider<
    Future<Mess> Function(Map<String, dynamic>, {MultipartFile? image})>((ref) {
  final repo = ref.read(messProfileRepositoryProvider);
  return (fields, {image}) =>
      repo.updateMyMess(fields: fields, imageFile: image);
});
