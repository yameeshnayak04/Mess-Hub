// lib/features/manager_dashboard/domain/entities/mess_profile.dart

class MessProfile {
  final String messId;
  final String name;
  final String address;
  final String city;
  final String cuisine;
  final String serviceType;
  final double? dailyThaliRate;
  final int totalMembers;
  final double averageRating;
  final int totalRatings;
  final List<MealPlan> mealPlans;

  const MessProfile({
    required this.messId,
    required this.name,
    required this.address,
    required this.city,
    required this.cuisine,
    required this.serviceType,
    this.dailyThaliRate,
    required this.totalMembers,
    required this.averageRating,
    required this.totalRatings,
    required this.mealPlans,
  });
}

class MealPlan {
  final String name;
  final double price;
  final double perThaliRebateRate;

  const MealPlan({
    required this.name,
    required this.price,
    required this.perThaliRebateRate,
  });
}
