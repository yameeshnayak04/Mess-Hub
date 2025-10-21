// lib/features/kiosk/domain/entities/kiosk_member.dart

class KioskMember {
  final String membershipId;
  final String customerId;
  final String name;
  final String phone;
  final String? photoUrl;
  final String status; // 'available', 'eaten', 'onLeave', 'toggled'

  const KioskMember({
    required this.membershipId,
    required this.customerId,
    required this.name,
    required this.phone,
    this.photoUrl,
    required this.status,
  });
}
