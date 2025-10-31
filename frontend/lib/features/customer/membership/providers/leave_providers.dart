// lib/features/customer/membership/providers/leave_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../repositories/leave_repository.dart';

final leaveRepositoryProvider = Provider((ref) {
  return LeaveRepository(ref.watch(dioClientProvider));
});
