import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../repositories/leave_repository.dart';

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  return LeaveRepository(ref.watch(dioClientProvider));
});

// Manager pending leaves
final managerLeaveRequestsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ref.watch(leaveRepositoryProvider).getLeaveRequestsForMyMess();
});
