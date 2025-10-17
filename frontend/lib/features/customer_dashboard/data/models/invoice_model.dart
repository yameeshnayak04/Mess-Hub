// lib/features/customer_dashboard/data/models/invoice_model.dart

import 'package:mess_management_system/features/customer_dashboard/domain/entities/invoice.dart';

class InvoiceModel extends Invoice {
  const InvoiceModel({
    required super.id,
    required super.month,
    required super.year,
    required super.amount,
    required super.status,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['_id'],
      month: json['month'].toString(), // Ensure month is a string
      year: json['year'],
      amount: (json['amount'] as num).toDouble(),
      status: json['status'],
    );
  }
}
