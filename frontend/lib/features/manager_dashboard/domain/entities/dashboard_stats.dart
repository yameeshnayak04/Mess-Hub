// lib/features/manager_dashboard/domain/entities/dashboard_stats.dart

// This entity defines the pure business object for the dashboard statistics.
// It is UI-agnostic and contains no parsing logic. It perfectly matches the
// data structure returned by your backend's dashboard-stats API endpoint.
class DashboardStats {
  final int totalMembers;
  final int membersOnLeave;
  final int mealsToPrepare;
  final int totalMealsEaten;
  final int monthlyMembersEaten;
  final int dailyUsersEaten;
  final int membersRemaining;

  const DashboardStats({
    required this.totalMembers,
    required this.membersOnLeave,
    required this.mealsToPrepare,
    required this.totalMealsEaten,
    required this.monthlyMembersEaten,
    required this.dailyUsersEaten,
    required this.membersRemaining,
  });
}
