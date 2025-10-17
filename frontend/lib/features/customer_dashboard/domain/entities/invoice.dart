// lib/features/customer_dashboard/domain/entities/invoice.dart

// Defines the Invoice entity for a monthly bill.
class Invoice {
  final String id;
  final String month;
  final int year;
  final double amount;
  final String status; // 'due', 'pending_approval', 'paid', 'rejected'

  const Invoice({
    required this.id,
    required this.month,
    required this.year,
    required this.amount,
    required this.status,
  });
}
