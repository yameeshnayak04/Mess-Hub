// lib/models/dashboard_stats.dart
class DashboardStats {
  final String liveStatus; // "Open" | "Closed"
  final String currentMeal; // "Lunch" | "Dinner" | "None"
  final int eaten; // members who have eaten this meal window
  final int onLeave; // members on leave for current meal
  final int skipped; // members who skipped current meal
  final int totalActiveMembers; // eligible members for current meal (active)
  final int? dailyMembers; // daily-plan members for current meal (optional)

  const DashboardStats({
    required this.liveStatus,
    required this.currentMeal,
    required this.eaten,
    required this.onLeave,
    required this.skipped,
    required this.totalActiveMembers,
    this.dailyMembers,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      liveStatus: (json['liveStatus'] ?? 'Closed') as String,
      currentMeal: (json['currentMeal'] ?? 'None') as String,
      eaten: (json['eaten'] ?? json['eatingNow'] ?? 0) as int,
      onLeave: (json['onLeave'] ?? 0) as int,
      skipped: (json['skipped'] ?? json['notEating'] ?? 0) as int,
      totalActiveMembers: (json['totalActiveMembers'] ?? 0) as int,
      dailyMembers:
          json['dailyMembers'] == null ? null : (json['dailyMembers'] as int),
    );
  }

  Map<String, dynamic> toJson() => {
        'liveStatus': liveStatus,
        'currentMeal': currentMeal,
        'eaten': eaten,
        'onLeave': onLeave,
        'skipped': skipped,
        'totalActiveMembers': totalActiveMembers,
        if (dailyMembers != null) 'dailyMembers': dailyMembers,
      };
}
