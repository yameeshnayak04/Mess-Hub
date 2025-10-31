// lib/features/customer/membership/providers/attendance_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/dio_client_provider.dart';
import '../repositories/attendance_repository.dart';

// Repo
final attendanceRepositoryProvider = Provider((ref) {
  return AttendanceRepository(ref.watch(dioClientProvider));
});

// Calendar params with proper equality
class AttendanceCalendarParams {
  final String membershipId;
  final int? month;
  final int? year;

  AttendanceCalendarParams(this.membershipId, {this.month, this.year});

  // Add equality operators
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceCalendarParams &&
          runtimeType == other.runtimeType &&
          membershipId == other.membershipId &&
          month == other.month &&
          year == other.year;

  @override
  int get hashCode => membershipId.hashCode ^ month.hashCode ^ year.hashCode;
}

// Calendar provider
final attendanceCalendarProvider = FutureProvider.family
    .autoDispose<List<dynamic>, AttendanceCalendarParams>((ref, p) async {
  return ref.watch(attendanceRepositoryProvider).getMyCalendar(
        membershipId: p.membershipId,
        month: p.month,
        year: p.year,
      );
});
