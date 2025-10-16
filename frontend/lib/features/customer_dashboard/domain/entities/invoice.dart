// Defines the Invoice entity for a monthly bill.

class Invoice {
  final String id;
  final String month;
  final double amount;
  final String status; // e.g., 'due', 'pending_approval', 'paid'

  const Invoice({
    required this.id,
    required this.month,
    required this.amount,
    required this.status,
  });
}
