// lib/models/attendance.dart
import '../core/utils/json_parse.dart';

/// The four states the backend records per membership, per day, per meal.
/// "Remaining" is deliberately NOT one of them - it is computed at query time
/// (meal window still open and nothing recorded yet) and never stored.
class AttendanceStatus {
  static const present = 'Present';
  static const skipped = 'Skipped';
  static const leave = 'Leave';
  static const absent = 'Absent';
}

/// One row from GET /attendance/:membershipId/calendar.
///
/// The calendar comes back grouped per day, so a day carries a status per
/// meal rather than the flat one-row-per-record list the old API returned.
class AttendanceDay {
  /// Plain calendar date 'YYYY-MM-DD'.
  final String date;

  /// Meal name -> status, e.g. { 'Lunch': 'Present', 'Dinner': 'Skipped' }.
  /// A meal missing from this map simply has no record yet.
  final Map<String, String> meals;

  AttendanceDay({required this.date, required this.meals});

  factory AttendanceDay.fromJson(Map<String, dynamic> json) {
    final raw = json['meals'];
    final meals = <String, String>{};
    if (raw is Map) {
      raw.forEach((key, value) => meals[key.toString()] = value.toString());
    }
    return AttendanceDay(
      date: asCalendarDate(json['date']) ?? '',
      meals: meals,
    );
  }

  DateTime? get dateTime => parseCalendarDate(date);

  String? get lunch => meals['Lunch'];
  String? get dinner => meals['Dinner'];

  bool get hasAnyLeave => meals.values.contains(AttendanceStatus.leave);
  bool get hasAnyPresent => meals.values.contains(AttendanceStatus.present);
  bool get hasAnySkipped => meals.values.contains(AttendanceStatus.skipped);
  bool get hasAnyAbsent => meals.values.contains(AttendanceStatus.absent);
}

/// GET /attendance/:membershipId/calendar
class AttendanceCalendar {
  final int month;
  final int year;
  final List<AttendanceDay> days;

  AttendanceCalendar({
    required this.month,
    required this.year,
    required this.days,
  });

  factory AttendanceCalendar.fromJson(Map<String, dynamic> json) =>
      AttendanceCalendar(
        month: asInt(json['month']) ?? 0,
        year: asInt(json['year']) ?? 0,
        days: (json['days'] is List)
            ? (json['days'] as List)
                .whereType<Map>()
                .map((e) =>
                    AttendanceDay.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : const <AttendanceDay>[],
      );

  AttendanceDay? dayFor(DateTime date) {
    final key = formatCalendarDate(date);
    for (final day in days) {
      if (day.date == key) return day;
    }
    return null;
  }
}

/// What a write returns (skip, kiosk mark, leave override).
class AttendanceRecord {
  final String? membershipId;
  final String serviceDate;
  final String meal;
  final String status;

  AttendanceRecord({
    this.membershipId,
    required this.serviceDate,
    required this.meal,
    required this.status,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        membershipId: asNullableId(json['membershipId']),
        serviceDate: asCalendarDate(json['serviceDate']) ?? '',
        meal: json['meal'] as String? ?? '',
        status: json['status'] as String? ?? '',
      );
}

/// Extra detail returned when a mid-leave member is marked Present.
class LeaveOverrideResult {
  final AttendanceRecord attendance;

  /// Days of the leave that had already run before today.
  final int elapsedLeaveDays;

  /// Whether that elapsed part still met the mess minimum and kept its
  /// rebate. When false, those days were converted to Absent instead.
  final bool elapsedLeaveKept;

  /// The date the shortened leave now ends, or null when the whole leave was
  /// discarded.
  final String? leaveEndedOn;

  LeaveOverrideResult({
    required this.attendance,
    required this.elapsedLeaveDays,
    required this.elapsedLeaveKept,
    this.leaveEndedOn,
  });

  factory LeaveOverrideResult.fromJson(Map<String, dynamic> json) =>
      LeaveOverrideResult(
        attendance: AttendanceRecord.fromJson(json),
        elapsedLeaveDays: asInt(json['elapsedLeaveDays']) ?? 0,
        elapsedLeaveKept: asBool(json['elapsedLeaveKept']),
        leaveEndedOn: asCalendarDate(json['leaveEndedOn']),
      );

  /// Plain-language summary for a confirmation toast.
  String get summary {
    if (elapsedLeaveKept) {
      return 'Marked present. The first $elapsedLeaveDays day(s) of leave still count.';
    }
    return elapsedLeaveDays == 0
        ? 'Marked present. The leave has been cancelled.'
        : 'Marked present. The leave was too short to qualify, so the '
            '$elapsedLeaveDays day(s) already taken count as absent.';
  }
}
