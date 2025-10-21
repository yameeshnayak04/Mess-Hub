// lib/features/manager_dashboard/domain/entities/dashboard_stats.dart

class DashboardStats {
  final int totalMembers;
  final int membersOnLeave;
  final int mealsToPrepareLunch;
  final int mealsToPrepareDinner;
  final int totalMealsEaten;
  final int monthlyMembersEaten;
  final int dailyUsersEaten;

  const DashboardStats({
    required this.totalMembers,
    required this.membersOnLeave,
    required this.mealsToPrepareLunch,
    required this.mealsToPrepareDinner,
    required this.totalMealsEaten,
    required this.monthlyMembersEaten,
    required this.dailyUsersEaten,
  });
}
