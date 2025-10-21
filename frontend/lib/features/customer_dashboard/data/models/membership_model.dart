// lib/features/customer_dashboard/data/models/membership_model.dart

import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';

class MembershipModel extends Membership {
  MembershipModel({
    required super.id,
    required super.messId,
    required super.messName,
    required super.userId,
    required super.mealPlan,
    required super.status,
    required super.monthlyFee,
    required super.joinDate,
    super.startDate,
    super.rejectionReason,
    super.messAddress,
    super.managerContact,
    super.messRating,
  });

  factory MembershipModel.fromJson(Map<String, dynamic> json) {
    return MembershipModel(
      id: json['_id'] ?? '',
      messId: json['messId']?['_id'] ?? json['messId'] ?? '',
      messName: json['messId']?['name'] ?? json['messName'] ?? 'Unknown Mess',
      userId: json['userId']?['_id'] ?? json['userId'] ?? '',
      mealPlan: json['mealPlan'] ?? 'Lunch',
      status: json['status'] ?? 'pending',
      monthlyFee: (json['monthlyFee'] as num?)?.toDouble() ?? 0.0,
      joinDate:
          DateTime.parse(json['joinDate'] ?? DateTime.now().toIso8601String()),
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      rejectionReason: json['rejectionReason'],
      messAddress: json['messId']?['address'],
      managerContact: json['messId']?['managerContact'],
      messRating: (json['messId']?['averageRating'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'messId': messId,
      'messName': messName,
      'userId': userId,
      'mealPlan': mealPlan,
      'status': status,
      'monthlyFee': monthlyFee,
      'joinDate': joinDate.toIso8601String(),
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    };
  }
}
