// This file defines the Invoice entity.

class Invoice {
  final String id;
  final String month;
  final double amount;
  final String status;

  const Invoice({
    required this.id,
    required this.month,
    required this.amount,
    required this.status,
  });
}
