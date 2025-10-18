// lib/features/manager_dashboard/domain/entities/weekly_menu.dart
class WeeklyMenu {
  final List<DayMenu> days;
  const WeeklyMenu({required this.days});
}

class DayMenu {
  final String day; // "Monday", "Tuesday", etc.
  final String? lunch;
  final String? dinner;
  const DayMenu({required this.day, this.lunch, this.dinner});
}
