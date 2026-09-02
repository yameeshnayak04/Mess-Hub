// lib/features/manager/menu/providers/manager_menu_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../../../../models/menu.dart';
import '../repositories/manager_menu_repository.dart';

final managerMenuRepositoryProvider = Provider<ManagerMenuRepository>((ref) {
  return ManagerMenuRepository(ref.watch(dioClientProvider));
});

final todaysMenuProvider = FutureProvider.autoDispose<Menu?>((ref) async {
  final repo = ref.watch(managerMenuRepositoryProvider);
  return repo.getMenuForDate(DateTime.now());
});

// Editor helpers
final menuForDateProvider = FutureProvider.family
    .autoDispose<Menu?, DateTime>((ref, date) async {
  final repo = ref.watch(managerMenuRepositoryProvider);
  return repo.getMenuForDate(date);
});
