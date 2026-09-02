// lib/models/membership.dart
import '../core/utils/json_parse.dart';

class Membership {
  final String id;
  final String userId;
  final String messId;
  final String planId;
  final String planName;

  /// The plan's CURRENT rate. The backend no longer stores a rate on the
  /// membership - it joins to the plan on every read - so this can change
  /// between billing cycles if the manager edits the plan. Never cache it;
  /// always show what the latest fetch returned.
  final double rateRupees;

  final String status; // 'Pending' | 'Active' | 'Inactive'

  /// Plain calendar date 'YYYY-MM-DD' - not an instant, so no timezone maths.
  final String? joinedDate;

  /// True once the member has asked to leave and is awaiting the manager.
  /// While true the membership is frozen: no attendance, no new leave.
  final bool discontinuationRequested;

  final String? messName;
  final String? memberName;
  final String? memberPhone;

  Membership({
    required this.id,
    required this.userId,
    required this.messId,
    required this.planId,
    required this.planName,
    required this.rateRupees,
    required this.status,
    this.joinedDate,
    this.discontinuationRequested = false,
    this.messName,
    this.memberName,
    this.memberPhone,
  });

  factory Membership.fromJson(Map<String, dynamic> json) => Membership(
        id: asId(json['id']),
        userId: asId(json['userId']),
        messId: asId(json['messId']),
        planId: asId(json['planId']),
        planName: json['planName'] as String? ?? '',
        rateRupees: asDouble(json['rateRupees']) ?? 0,
        status: json['status'] as String? ?? 'Pending',
        joinedDate: asCalendarDate(json['joinedDate']),
        discontinuationRequested: asBool(json['discontinuationRequested']),
        messName: json['messName'] as String?,
        memberName: json['memberName'] as String?,
        memberPhone: json['memberPhone'] as String?,
      );

  bool get isActive => status == 'Active';
  bool get isPending => status == 'Pending';

  DateTime? get joinedDateTime => parseCalendarDate(joinedDate);

  Membership copyWith({
    String? id,
    String? userId,
    String? messId,
    String? planId,
    String? planName,
    double? rateRupees,
    String? status,
    String? joinedDate,
    bool? discontinuationRequested,
    String? messName,
    String? memberName,
    String? memberPhone,
  }) {
    return Membership(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      messId: messId ?? this.messId,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      rateRupees: rateRupees ?? this.rateRupees,
      status: status ?? this.status,
      joinedDate: joinedDate ?? this.joinedDate,
      discontinuationRequested:
          discontinuationRequested ?? this.discontinuationRequested,
      messName: messName ?? this.messName,
      memberName: memberName ?? this.memberName,
      memberPhone: memberPhone ?? this.memberPhone,
    );
  }
}
