// lib/models/dashboard_stats.dart
class DashboardStats {
  final String liveStatus; // "Open" | "Closed"
  final String currentMeal; // "Lunch" | "Dinner" | "None"
  final int eatingNow;
  final int onLeave;
  final int notEating;
  final int totalActiveMembers;
  final int? dailyMembers; // present for 'Both Daily & Monthly'

  DashboardStats({
    required this.liveStatus,
    required this.currentMeal,
    required this.eatingNow,
    required this.onLeave,
    required this.notEating,
    required this.totalActiveMembers,
    this.dailyMembers,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      liveStatus: json['liveStatus'] as String,
      currentMeal: json['currentMeal'] as String,
      eatingNow: json['eatingNow'] as int,
      onLeave: json['onLeave'] as int,
      notEating: json['notEating'] as int,
      totalActiveMembers: json['totalActiveMembers'] as int,
      dailyMembers: json['dailyMembers'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'liveStatus': liveStatus,
        'currentMeal': currentMeal,
        'eatingNow': eatingNow,
        'onLeave': onLeave,
        'notEating': notEating,
        'totalActiveMembers': totalActiveMembers,
        if (dailyMembers != null) 'dailyMembers': dailyMembers,
      };
}
