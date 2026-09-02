// lib/models/dashboard_stats.dart
import '../core/utils/json_parse.dart';
import 'menu.dart';

/// GET /messes/my-mess/dashboard
///
/// The backend computes all of this in one grouped query and returns the
/// counts nested under `counts`.
class DashboardStats {
  /// Plain calendar date the counts refer to.
  final String date;

  /// The meal these counts are for - the one being served now, or the next
  /// one if the mess is currently closed.
  final String meal;

  final String liveStatus; // 'Open' | 'Closed'

  /// null when no meal is being served right now.
  final String? currentMeal;

  final String nextMeal;
  final bool nextMealIsTomorrow;

  /// Members whose plan covers this meal.
  final int eligible;
  final int eating;
  final int skipped;
  final int onLeave;
  final int absent;

  /// Eligible members with no record yet. Never stored - the backend derives
  /// it, and it falls to zero on its own once the absence job runs.
  final int remaining;

  /// Walk-in thali sales for this meal today.
  final int walkins;

  final Menu? todaysMenu;

  const DashboardStats({
    required this.date,
    required this.meal,
    required this.liveStatus,
    this.currentMeal,
    required this.nextMeal,
    required this.nextMealIsTomorrow,
    required this.eligible,
    required this.eating,
    required this.skipped,
    required this.onLeave,
    required this.absent,
    required this.remaining,
    required this.walkins,
    this.todaysMenu,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final counts = (json['counts'] is Map)
        ? Map<String, dynamic>.from(json['counts'] as Map)
        : const <String, dynamic>{};

    return DashboardStats(
      date: asCalendarDate(json['date']) ?? '',
      meal: json['meal'] as String? ?? 'Lunch',
      liveStatus: json['liveStatus'] as String? ?? 'Closed',
      currentMeal: json['currentMeal'] as String?,
      nextMeal: json['nextMeal'] as String? ?? 'Lunch',
      nextMealIsTomorrow: asBool(json['nextMealIsTomorrow']),
      eligible: asInt(counts['eligible']) ?? 0,
      eating: asInt(counts['eating']) ?? 0,
      skipped: asInt(counts['skipped']) ?? 0,
      onLeave: asInt(counts['onLeave']) ?? 0,
      absent: asInt(counts['absent']) ?? 0,
      remaining: asInt(counts['remaining']) ?? 0,
      walkins: asInt(counts['walkins']) ?? 0,
      todaysMenu: json['todaysMenu'] is Map
          ? Menu.fromJson(Map<String, dynamic>.from(json['todaysMenu'] as Map))
          : null,
    );
  }

  bool get isOpen => liveStatus == 'Open';

  /// How many thalis still need cooking for this meal.
  int get expectedThalis => eating + remaining;
}

/// One row from GET /messes/my-mess/dashboard/members?status=...
class DashboardMember {
  final String membershipId;
  final String userId;
  final String name;
  final String phone;

  /// 'Present' | 'Skipped' | 'Leave' | 'Absent' | 'Remaining'
  final String status;

  DashboardMember({
    required this.membershipId,
    required this.userId,
    required this.name,
    required this.phone,
    required this.status,
  });

  factory DashboardMember.fromJson(Map<String, dynamic> json) =>
      DashboardMember(
        membershipId: asId(json['membershipId']),
        userId: asId(json['userId']),
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        status: json['status'] as String? ?? 'Remaining',
      );

  bool get isOnLeave => status == 'Leave';
}
