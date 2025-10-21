// lib/features/customer_dashboard/domain/entities/attendance_day.dart

class AttendanceDay {
  final DateTime date;
  final bool lunchAttended;
  final bool dinnerAttended;
  final bool hasLunchPlan;
  final bool hasDinnerPlan;

  AttendanceDay({
    required this.date,
    required this.lunchAttended,
    required this.dinnerAttended,
    required this.hasLunchPlan,
    required this.hasDinnerPlan,
  });

  // Helper to check if any meal was attended
  bool get hasAnyAttendance => lunchAttended || dinnerAttended;

  // Check if fully attended (all subscribed meals)
  bool get isFullyAttended {
    if (hasLunchPlan && hasDinnerPlan) {
      return lunchAttended && dinnerAttended;
    }
    if (hasLunchPlan) return lunchAttended;
    if (hasDinnerPlan) return dinnerAttended;
    return false;
  }

  // Check if partially attended
  bool get isPartiallyAttended {
    if (hasLunchPlan && hasDinnerPlan) {
      return (lunchAttended && !dinnerAttended) ||
          (!lunchAttended && dinnerAttended);
    }
    return false;
  }

  // Check if completely missed
  bool get isFullyMissed {
    if (hasLunchPlan && !lunchAttended) return true;
    if (hasDinnerPlan && !dinnerAttended) return true;
    return false;
  }

  // Get attendance count for dots display
  int get attendanceCount {
    int count = 0;
    if (hasLunchPlan && lunchAttended) count++;
    if (hasDinnerPlan && dinnerAttended) count++;
    return count;
  }

  // Get total possible meals for this plan
  int get totalMealsCount {
    int count = 0;
    if (hasLunchPlan) count++;
    if (hasDinnerPlan) count++;
    return count;
  }
}
