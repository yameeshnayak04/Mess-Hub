class DashboardStats {
  final String liveStatus;
  final String currentMeal;
  final int eatingNow;
  final int onLeave;
  final int notEating;
  final int totalActiveMembers;
  final int? dailyMembers;

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

  Map<String, dynamic> toJson() {
    return {
      'liveStatus': liveStatus,
      'currentMeal': currentMeal,
      'eatingNow': eatingNow,
      'onLeave': onLeave,
      'notEating': notEating,
      'totalActiveMembers': totalActiveMembers,
      if (dailyMembers != null) 'dailyMembers': dailyMembers,
    };
  }
}
