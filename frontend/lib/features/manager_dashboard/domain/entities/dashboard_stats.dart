// This file defines the DashboardStats entity, a pure Dart object for the UI.

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
