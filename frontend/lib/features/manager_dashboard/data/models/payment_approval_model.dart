// lib/features/manager_dashboard/data/models/payment_approval_model.dart

import 'package:mess_management_system/features/manager_dashboard/domain/entities/payment_approval.dart';

class PaymentApprovalModel extends PaymentApproval {
  const PaymentApprovalModel({
    required super.invoiceId,
    required super.membershipId,
    required super.customerName,
    required super.customerPhone,
    super.customerPhoto,
    required super.month,
    required super.year,
    required super.amount,
    super.proofUrl,
    super.submittedAt,
  });

  factory PaymentApprovalModel.fromJson(Map<String, dynamic> json) {
    final membership = json['membership'] as Map<String, dynamic>;
    final customer = membership['customer'] as Map<String, dynamic>;

    return PaymentApprovalModel(
      invoiceId: json['_id'],
      membershipId: membership['_id'],
      customerName: customer['name'],
      customerPhone: customer['phone'],
      customerPhoto: customer['photoUrl'],
      month: json['month'],
      year: json['year'],
      amount: (json['amount'] as num).toDouble(),
      proofUrl: json['proofUrl'],
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'])
          : null,
    );
  }
}
