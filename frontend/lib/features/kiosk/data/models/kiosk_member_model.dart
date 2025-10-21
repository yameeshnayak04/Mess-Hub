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

  factory KioskMemberModel.fromJson(Map<String, dynamic> json) {
    return KioskMemberModel(
      membershipId: json['membershipId'] ?? '',
      customerId: json['_id'],
      name: json['name'],
      phone: json['phone'],
      photoUrl: json['photoUrl'],
      status: json['status'] ?? 'available',
    );
  }
}
