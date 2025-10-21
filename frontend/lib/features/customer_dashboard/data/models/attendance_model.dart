// lib/features/customer_dashboard/data/models/attendance_model.dart

import 'package:mess_management_system/features/customer_dashboard/domain/entities/attendance_day.dart';

class AttendanceModel extends AttendanceDay {
  AttendanceModel({
    required super.date,
    required super.lunchAttended,
    required super.dinnerAttended,
    required super.hasLunchPlan,
    required super.hasDinnerPlan,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json, String mealPlan) {
    final hasLunch = mealPlan == 'Lunch' || mealPlan == 'Full Day';
    final hasDinner = mealPlan == 'Dinner' || mealPlan == 'Full Day';

    return AttendanceModel(
      date: DateTime.parse(json['date']),
      lunchAttended: json['lunchAttended'] ?? false,
      dinnerAttended: json['dinnerAttended'] ?? false,
      hasLunchPlan: hasLunch,
      hasDinnerPlan: hasDinner,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'lunchAttended': lunchAttended,
      'dinnerAttended': dinnerAttended,
    };
  }
}
