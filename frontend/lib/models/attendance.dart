// lib/models/attendance.dart
class Attendance {
  final String id;
  final String? user; // nullable for Daily walk-ins
  final String mess;
  final DateTime date;
  final String mealType; // 'Lunch' | 'Dinner'
  final String status; // 'Present' | 'Skipped' | 'Leave' | 'Absent'
  final String memberType; // 'Monthly' | 'Daily'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Attendance({
    required this.id,
    this.user,
    required this.mess,
    required this.date,
    required this.mealType,
    required this.status,
    required this.memberType,
    this.createdAt,
    this.updatedAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['_id'] as String,
      user: json['user'] as String?,
      mess: json['mess'] as String,
      date: DateTime.parse(json['date'] as String),
      mealType: json['mealType'] as String,
      status: json['status'] as String,
      memberType: json['memberType'] as String,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        if (user != null) 'user': user,
        'mess': mess,
        'date': date.toIso8601String(),
        'mealType': mealType,
        'status': status,
        'memberType': memberType,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };
}
