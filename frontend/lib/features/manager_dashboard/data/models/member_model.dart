// lib/features/manager_dashboard/data/models/member_model.dart

import 'package:mess_management_system/features/manager_dashboard/domain/entities/member.dart';

class MemberModel extends Member {
  const MemberModel({
    required super.membershipId,
    required super.customerId,
    required super.customerName,
    required super.customerPhone,
    super.customerPhoto,
    required super.planName,
    required super.planPrice,
    required super.status,
    required super.startedAt,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>;
    final mealPlan = json['mealPlan'] as Map<String, dynamic>;
    return MemberModel(
      membershipId: json['_id'],
      customerId: customer['_id'],
      customerName: customer['name'],
      customerPhone: customer['phone'],
      customerPhoto: customer['photoUrl'],
      planName: mealPlan['name'],
      planPrice: (mealPlan['price'] as num).toDouble(),
      status: json['status'],
      startedAt: DateTime.parse(json['startedAt']),
    );
  }
}
