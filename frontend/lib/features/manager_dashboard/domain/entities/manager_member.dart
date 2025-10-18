// lib/features/manager_dashboard/domain/entities/manager_member.dart
class ManagerMember {
  final String id; // This is the User ID
  final String name;
  final String phone;
  final String? photoUrl;
  final String mealPlanName;

  const ManagerMember({
    required this.id,
    required this.name,
    required this.phone,
    this.photoUrl,
    required this.mealPlanName,
  });
}
