// lib/features/manager_dashboard/data/models/member_detail_model.dart

import 'package:mess_management_system/features/manager_dashboard/domain/entities/member_detail.dart';

class AttendanceRecordModel extends AttendanceRecord {
  const AttendanceRecordModel({
    required super.date,
    required super.mealType,
    required super.isOverride,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      date: DateTime.parse(json['date']),
      mealType: json['mealType'],
      isOverride: json['isManagerOverride'] ?? false,
    );
  }
}

class PaymentHistoryModel extends PaymentHistory {
  const PaymentHistoryModel({
    required super.invoiceId,
    required super.month,
    required super.year,
    required super.amount,
    required super.status,
    super.paidAt,
  });

  factory PaymentHistoryModel.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryModel(
      invoiceId: json['_id'],
      month: json['month'],
      year: json['year'],
      amount: (json['amount'] as num).toDouble(),
      status: json['status'],
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
    );
  }
}

class MemberDetailModel extends MemberDetail {
  const MemberDetailModel({
    required super.membershipId,
    required super.customerName,
    required super.customerPhone,
    super.customerPhoto,
    required super.planName,
    required super.planPrice,
    required super.startedAt,
    required super.status,
    required super.attendance,
    required super.payments,
  });

  factory MemberDetailModel.fromJson(Map<String, dynamic> json) {
    final membership = json['membership'] as Map<String, dynamic>;
    final customer = membership['customer'] as Map<String, dynamic>;
    final mealPlan = membership['mealPlan'] as Map<String, dynamic>;

    final attendanceList = (json['attendance'] as List?)
            ?.map((a) => AttendanceRecordModel.fromJson(a))
            .toList() ??
        [];

    final paymentsList = (json['invoices'] as List?)
            ?.map((inv) => PaymentHistoryModel.fromJson(inv))
            .toList() ??
        [];

    return MemberDetailModel(
      membershipId: membership['_id'],
      customerName: customer['name'],
      customerPhone: customer['phone'],
      customerPhoto: customer['photoUrl'],
      planName: mealPlan['name'],
      planPrice: (mealPlan['price'] as num).toDouble(),
      startedAt: DateTime.parse(membership['startedAt']),
      status: membership['status'],
      attendance: attendanceList,
      payments: paymentsList,
    );
  }
}
