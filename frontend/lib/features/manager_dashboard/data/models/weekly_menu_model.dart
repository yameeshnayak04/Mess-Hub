// In frontend/lib/features/manager_dashboard/data/models/weekly_menu_model.dart
import 'package:mess_management_system/features/manager_dashboard/domain/entities/weekly_menu.dart';

class WeeklyMenuModel extends WeeklyMenu {
  const WeeklyMenuModel({required super.days});
  factory WeeklyMenuModel.fromJson(Map<String, dynamic> json) {
    return WeeklyMenuModel(
      days: (json['days'] as List?)
              ?.map((d) => DayMenuModel.fromJson(d))
              .toList() ??
          [],
    );
  }
}

class DayMenuModel extends DayMenu {
  const DayMenuModel({required super.day, super.lunch, super.dinner});
  factory DayMenuModel.fromJson(Map<String, dynamic> json) {
    return DayMenuModel(
        day: json['day'] ?? 'Unknown',
        lunch: json['lunch'],
        dinner: json['dinner']);
  }
}
