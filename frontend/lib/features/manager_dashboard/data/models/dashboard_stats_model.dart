// lib/features/manager_dashboard/data/models/dashboard_stats_model.dart

import 'package:mess_management_system/features/manager_dashboard/domain/entities/dashboard_stats.dart';

class DashboardStatsModel extends DashboardStats {
  const DashboardStatsModel({
    required super.totalMembers,
    required super.membersOnLeave,
    required super.mealsToPrepareLunch,
    required super.mealsToPrepareDinner,
    required super.totalMealsEaten,
    required super.monthlyMembersEaten,
    required super.dailyUsersEaten,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalMembers: json['totalMembers'] ?? 0,
      membersOnLeave: json['membersOnLeave'] ?? 0,
      mealsToPrepareLunch: json['mealsToPrepareLunch'] ?? 0,
      mealsToPrepareDinner: json['mealsToPrepareDinner'] ?? 0,
      totalMealsEaten: json['totalMealsEaten'] ?? 0,
      monthlyMembersEaten: json['monthlyMembersEaten'] ?? 0,
      dailyUsersEaten: json['dailyUsersEaten'] ?? 0,
    );
  }
}
