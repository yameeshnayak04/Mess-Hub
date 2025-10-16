// This file defines the InvoiceModel for parsing API data.

import 'package:mess_management_system/features/customer_dashboard/domain/entities/invoice.dart';

class InvoiceModel extends Invoice {
  const InvoiceModel({
    required super.id,
    required super.month,
    required super.amount,
    required super.status,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['_id'],
      month: json['month'].toString(), // Ensure month is a string
      amount: (json['amount'] as num).toDouble(),
      status: json['status'],
    );
  }
}
