// This file defines the DashboardStatsModel, which can be created from JSON.

import 'package:mess_management_system/features/manager_dashboard/domain/entities/dashboard_stats.dart';

// The model extends the entity for easy conversion.
class DashboardStatsModel extends DashboardStats {
  const DashboardStatsModel({
    required super.totalMembers,
    required super.membersOnLeave,
    required super.mealsToPrepare,
    required super.totalMealsEaten,
    required super.monthlyMembersEaten,
    required super.dailyUsersEaten,
    required super.membersRemaining,
  });

  // The factory constructor creates a DashboardStatsModel instance from a JSON map.
  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalMembers: json['totalMembers'],
      membersOnLeave: json['membersOnLeave'],
      mealsToPrepare: json['mealsToPrepare'],
      totalMealsEaten: json['totalMealsEaten'],
      monthlyMembersEaten: json['monthlyMembersEaten'],
      dailyUsersEaten: json['dailyUsersEaten'],
      membersRemaining: json['membersRemaining'],
    );
  }
}
