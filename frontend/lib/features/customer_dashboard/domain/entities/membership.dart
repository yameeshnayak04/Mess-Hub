// lib/features/customer_dashboard/domain/entities/membership.dart

// Defines the Membership entity, a pure Dart object representing a user's subscription to a mess.
class Membership {
  final String id;
  final String messId; // Crucial for making specific API calls
  final String messName;
  final String messAddress;
  final String mealPlanName;
  final double mealPlanPrice;
  final String status;

  const Membership({
    required this.id,
    required this.messId,
    required this.messName,
    required this.messAddress,
    required this.mealPlanName,
    required this.mealPlanPrice,
    required this.status,
  });
}
