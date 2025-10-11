// This file defines the Membership entity, representing a user's subscription to a mess.

class Membership {
  final String id;
  final String messName;
  final String messAddress;
  final String mealPlanName;
  final double mealPlanPrice;
  final String status;

  const Membership({
    required this.id,
    required this.messName,
    required this.messAddress,
    required this.mealPlanName,
    required this.mealPlanPrice,
    required this.status,
  });
}
