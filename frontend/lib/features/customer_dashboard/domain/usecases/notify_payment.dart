// lib/features/customer_dashboard/domain/usecases/notify_payment.dart

import 'package:mess_management_system/features/customer_dashboard/domain/repositories/customer_repository.dart';

class NotifyPayment {
  final CustomerRepository repository;

  NotifyPayment(this.repository);

  // Use case for notifying the manager that a payment has been made.
  Future<void> call({
    required String invoiceId,
    String? proofUrl, // proofUrl is optional
  }) {
    return repository.notifyPayment(invoiceId, proofUrl);
  }
}
