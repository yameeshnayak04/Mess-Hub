// In frontend/lib/features/manager_dashboard/data/models/manager_member_model.dart
import 'package:mess_management_system/features/manager_dashboard/domain/entities/manager_member.dart';

class ManagerMemberModel extends ManagerMember {
  const ManagerMemberModel(
      {required super.id,
      required super.name,
      required super.phone,
      super.photoUrl,
      required super.mealPlanName});

  factory ManagerMemberModel.fromJson(Map<String, dynamic> json) {
    final customerData = json['customer'] as Map<String, dynamic>? ?? {};
    final mealPlanData = json['mealPlan'] as Map<String, dynamic>? ?? {};
    return ManagerMemberModel(
      id: customerData['_id'] ?? '',
      name: customerData['name'] ?? 'N/A',
      phone: customerData['phone'] ?? 'N/A',
      photoUrl: customerData['photoUrl'],
      mealPlanName: mealPlanData['name'] ?? 'N/A',
    );
  }
}
