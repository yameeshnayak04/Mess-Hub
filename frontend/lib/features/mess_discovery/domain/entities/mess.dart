// lib/features/mess_discovery/domain/entities/mess.dart

// A simple class to hold location coordinates.
class Location {
  final List<double> coordinates; // [longitude, latitude]
  const Location({required this.coordinates});
}

// Sub-entity for MealPlan
class MealPlan {
  final String id;
  final String name;
  final double currentPrice;
  const MealPlan(
      {required this.id, required this.name, required this.currentPrice});
}

// Sub-entity for Timings
class Timings {
  final String? lunchStart, lunchEnd, dinnerStart, dinnerEnd;
  const Timings(
      {this.lunchStart, this.lunchEnd, this.dinnerStart, this.dinnerEnd});
}

// --- NEW: A dedicated entity for mess rules ---
class MessRules {
  final int rebateMinDays;
  final int leaveCutoffDay;
  final String leaveApplicationDeadlineTime;
  final String notEatingRebatePolicy;
  final int? partialRebatePercentage; // Nullable

  const MessRules({
    required this.rebateMinDays,
    required this.leaveCutoffDay,
    required this.leaveApplicationDeadlineTime,
    required this.notEatingRebatePolicy,
    this.partialRebatePercentage,
  });
}
// ------------------------------------------

// The complete, updated Mess entity for the UI.
class Mess {
  final String id;
  final String name;
  final String address;
  final String managerContact;
  final String serviceType;
  final String cuisine;
  final double? dailyThaliRate;
  final List<MealPlan> mealPlans;
  final Timings timings;
  final double averageRating;
  final int reviewCount;
  final List<String> galleryUrls;
  final Location location;
  final MessRules rules; // <-- NEW: Added rules entity

  const Mess({
    required this.id,
    required this.name,
    required this.address,
    required this.managerContact,
    required this.serviceType,
    required this.cuisine,
    this.dailyThaliRate,
    required this.mealPlans,
    required this.timings,
    required this.averageRating,
    required this.reviewCount,
    required this.galleryUrls,
    required this.location,
    required this.rules, // <-- NEW: Added to constructor
  });
}
