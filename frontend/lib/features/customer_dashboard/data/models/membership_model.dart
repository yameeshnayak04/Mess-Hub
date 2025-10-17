// lib/features/customer_dashboard/data/models/membership_model.dart

// We import the entity from the domain layer.
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';

// The MembershipModel extends the Membership entity for easy conversion.
class MembershipModel extends Membership {
  const MembershipModel({
    required super.id,
    required super.messId,
    required super.messName,
    required super.messAddress,
    required super.mealPlanName,
    required super.mealPlanPrice,
    required super.status,
  });

  // The factory constructor creates a MembershipModel instance from a JSON map.
  // This is where we parse the complex JSON object returned by the backend.
  factory MembershipModel.fromJson(Map<String, dynamic> json) {
    // The backend uses .populate(), so 'mess' is a nested object.
    // We safely access it and provide default values in case it's unexpectedly null.
    final messData = json['mess'] as Map<String, dynamic>? ?? {};
    // 'mealPlan' is also a nested object within the membership document.
    final mealPlanData = json['mealPlan'] as Map<String, dynamic>? ?? {};

    return MembershipModel(
      id: json['_id'] ?? '',
      // We access the nested fields from the populated data.
      messId: messData['_id'] ?? '',
      messName: messData['name'] ?? 'Unknown Mess',
      messAddress: messData['address'] ?? 'No address',
      mealPlanName: mealPlanData['name'] ?? 'Unknown Plan',
      // We cast the number to a double to ensure type safety.
      mealPlanPrice: (mealPlanData['price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'inactive',
    );
  }
}
