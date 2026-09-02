// lib/models/leave.dart
import '../core/utils/json_parse.dart';

class Leave {
  final String id;
  final String membershipId;

  /// Inclusive calendar dates, exactly as the customer typed them. (Stored
  /// server-side as a half-open range; the API converts back on the way out.)
  final String startDate;
  final String endDate;

  final String? reason;
  final String? memberName;
  final String? memberPhone;

  Leave({
    required this.id,
    required this.membershipId,
    required this.startDate,
    required this.endDate,
    this.reason,
    this.memberName,
    this.memberPhone,
  });

  factory Leave.fromJson(Map<String, dynamic> json) => Leave(
        id: asId(json['id']),
        membershipId: asId(json['membershipId']),
        startDate: asCalendarDate(json['startDate']) ?? '',
        endDate: asCalendarDate(json['endDate']) ?? '',
        reason: json['reason'] as String?,
        memberName: json['memberName'] as String?,
        memberPhone: json['memberPhone'] as String?,
      );

  DateTime? get start => parseCalendarDate(startDate);
  DateTime? get end => parseCalendarDate(endDate);

  /// Inclusive day count - the number the mess's minimum-days rule checks.
  int get totalDays {
    final s = start;
    final e = end;
    if (s == null || e == null) return 0;
    return e.difference(s).inDays + 1;
  }
}
