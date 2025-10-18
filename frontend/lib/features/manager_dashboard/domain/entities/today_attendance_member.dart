// lib/features/manager_dashboard/domain/entities/today_attendance_member.dart
class TodayAttendanceMember {
  final String userId;
  final String name;
  final String? phone;
  final bool eaten;
  const TodayAttendanceMember({
    required this.userId,
    required this.name,
    this.phone,
    required this.eaten,
  });
}
