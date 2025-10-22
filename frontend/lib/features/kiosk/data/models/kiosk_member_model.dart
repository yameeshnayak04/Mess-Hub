// lib/features/kiosk/data/models/kiosk_member_model.dart
import 'package:mess_management_system/features/kiosk/domain/entities/kiosk_member.dart';

class KioskMemberModel extends KioskMember {
  const KioskMemberModel({
    required super.membershipId,
    required super.customerId,
    required super.name,
    required super.phone,
    super.photoUrl,
    required super.status,
  });

  factory KioskMemberModel.fromJson(Map json) {
    return KioskMemberModel(
      membershipId: (json['membershipId'] ?? '').toString(),
      customerId: (json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      photoUrl: (json['photoUrl'] ?? '').toString().isEmpty
          ? null
          : (json['photoUrl'] as String),
      status: (json['status'] ?? 'available').toString(),
    );
  }
}
