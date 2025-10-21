// lib/features/customer_dashboard/data/models/invoice_model.dart

import 'package:mess_management_system/features/customer_dashboard/domain/entities/invoice.dart';

class InvoiceModel extends Invoice {
  InvoiceModel({
    required super.id,
    required super.membershipId,
    required super.messName,
    required super.month,
    required super.year,
    required super.baseAmount,
    required super.daysPresent,
    required super.totalDays,
    required super.rebateAmount,
    required super.finalAmount,
    required super.status,
    required super.generatedDate,
    super.paidDate,
    super.paymentScreenshotUrl,
    super.rejectionReason,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['_id'] ?? '',
      membershipId: json['membership']?['_id'] ?? json['membership'] ?? '',
      messName: json['membership']?['messId']?['name'] ??
          json['messName'] ??
          'Unknown Mess',
      month: json['month'] ?? DateTime.now().month,
      year: json['year'] ?? DateTime.now().year,
      baseAmount: (json['baseAmount'] as num?)?.toDouble() ?? 0.0,
      daysPresent: json['daysPresent'] ?? 0,
      totalDays: json['totalDays'] ?? 30,
      rebateAmount: (json['rebateAmount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'pending',
      generatedDate:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      paidDate:
          json['paidDate'] != null ? DateTime.parse(json['paidDate']) : null,
      paymentScreenshotUrl: json['paymentScreenshot'],
      rejectionReason: json['rejectionReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'membership': membershipId,
      'month': month,
      'year': year,
      'baseAmount': baseAmount,
      'daysPresent': daysPresent,
      'totalDays': totalDays,
      'rebateAmount': rebateAmount,
      'finalAmount': finalAmount,
      'status': status,
      if (paidDate != null) 'paidDate': paidDate!.toIso8601String(),
      if (paymentScreenshotUrl != null)
        'paymentScreenshot': paymentScreenshotUrl,
    };
  }
}
