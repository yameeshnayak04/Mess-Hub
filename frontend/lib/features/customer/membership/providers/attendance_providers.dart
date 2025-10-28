import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../repositories/attendance_repository.dart';

// Repo
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.watch(dioClientProvider));
});

// Calendar
class AttendanceCalendarParams {
  final String membershipId;
  final int? month;
  final int? year;
  AttendanceCalendarParams(this.membershipId, {this.month, this.year});
}

final attendanceCalendarProvider = FutureProvider.family
    .autoDispose<List<dynamic>, AttendanceCalendarParams>((ref, p) async {
  return ref.watch(attendanceRepositoryProvider).getMyCalendar(
        membershipId: p.membershipId,
        month: p.month,
        year: p.year,
      );
});
