// lib/features/customer_dashboard/domain/entities/membership.dart

class Membership {
  final String id;
  final String messId;
  final String messName;
  final String userId;
  final String mealPlan; // 'Lunch', 'Dinner', 'Full Day'
  final String status; // 'pending', 'active', 'inactive'
  final double monthlyFee;
  final DateTime joinDate;
  final DateTime? startDate;
  final String? rejectionReason;

  // Mess details
  final String? messAddress;
  final String? managerContact;
  final double? messRating;

  Membership({
    required this.id,
    required this.messId,
    required this.messName,
    required this.userId,
    required this.mealPlan,
    required this.status,
    required this.monthlyFee,
    required this.joinDate,
    this.startDate,
    this.rejectionReason,
    this.messAddress,
    this.managerContact,
    this.messRating,
  });

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isInactive => status == 'inactive';

  // Helper to determine meal types included in plan
  List<String> get mealTypes {
    if (mealPlan == 'Full Day') return ['Lunch', 'Dinner'];
    return [mealPlan];
  }

  bool get hasLunch => mealTypes.contains('Lunch');
  bool get hasDinner => mealTypes.contains('Dinner');
  bool get isFullDay => mealPlan == 'Full Day';
}
