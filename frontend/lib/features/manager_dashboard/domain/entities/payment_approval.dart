// lib/features/manager_dashboard/domain/entities/payment_approval.dart

class PaymentApproval {
  final String invoiceId;
  final String membershipId;
  final String customerName;
  final String customerPhone;
  final String? customerPhoto;
  final int month;
  final int year;
  final double amount;
  final String? proofUrl;
  final DateTime? submittedAt;

  const PaymentApproval({
    required this.invoiceId,
    required this.membershipId,
    required this.customerName,
    required this.customerPhone,
    this.customerPhoto,
    required this.month,
    required this.year,
    required this.amount,
    this.proofUrl,
    this.submittedAt,
  });
}
