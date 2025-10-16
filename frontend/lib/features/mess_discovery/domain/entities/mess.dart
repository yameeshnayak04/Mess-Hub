// lib/features/mess_discovery/domain/entities/mess.dart

// This file defines the Mess entity, a pure Dart object for the UI.
// It represents all the public-facing information about a mess.

class Mess {
  final String id;
  final String name;
  final String address;
  final String managerContact;
  final String serviceType;
  final String cuisine;
  final double? dailyThaliRate; // Nullable if the mess is 'Monthly Only'
  final List<MealPlan> mealPlans;
  final Timings timings;
  final double averageRating;
  final int reviewCount;
  final List<String> galleryUrls;

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
  });
}

// Sub-entity for MealPlan, containing only what the customer needs to see.
class MealPlan {
  final String id;
  final String name; // e.g., 'Lunch', 'Dinner', 'Full Day'
  final double currentPrice;

  const MealPlan({
    required this.id,
    required this.name,
    required this.currentPrice,
  });
}

// Sub-entity for Timings.
class Timings {
  final String lunchStart;
  final String lunchEnd;
  final String dinnerStart;
  final String dinnerEnd;

  const Timings({
    required this.lunchStart,
    required this.lunchEnd,
    required this.dinnerStart,
    required this.dinnerEnd,
  });
}
