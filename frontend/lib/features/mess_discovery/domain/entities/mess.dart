// This file defines the Mess entity, a pure Dart object for the UI.

class Mess {
  final String id;
  final String name;
  final String address;
  final String managerContact;
  final String serviceType;
  final double? dailyThaliRate; // Nullable if the mess is 'Monthly Only'
  final List<MealPlan> mealPlans;
  final Timings timings;

  const Mess({
    required this.id,
    required this.name,
    required this.address,
    required this.managerContact,
    required this.serviceType,
    this.dailyThaliRate,
    required this.mealPlans,
    required this.timings,
  });
}

// Sub-entity for MealPlan
class MealPlan {
  final String id;
  final String name; // e.g., 'Lunch', 'Dinner'
  final double currentPrice;
  final double perDayRebateRate;

  const MealPlan({
    required this.id,
    required this.name,
    required this.currentPrice,
    required this.perDayRebateRate,
  });
}

// Sub-entity for Timings
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
