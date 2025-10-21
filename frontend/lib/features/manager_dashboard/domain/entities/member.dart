// lib/features/manager_dashboard/domain/entities/member.dart

class Member {
  final String membershipId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String? customerPhoto;
  final String planName;
  final double planPrice;
  final String status;
  final DateTime startedAt;

  const Member({
    required this.membershipId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.customerPhoto,
    required this.planName,
    required this.planPrice,
    required this.status,
    required this.startedAt,
  });
}
