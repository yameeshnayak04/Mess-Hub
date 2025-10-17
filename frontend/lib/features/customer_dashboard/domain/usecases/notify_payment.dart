// lib/features/customer_dashboard/domain/usecases/notify_payment.dart

import 'package:mess_management_system/features/customer_dashboard/domain/repositories/customer_repository.dart';

class NotifyPayment {
  final CustomerRepository repository;

  NotifyPayment(this.repository);

  // The use case for notifying the manager that a payment has been made.
  Future<void> call({
    required String invoiceId,
    String? proofUrl, // The URL for the payment proof screenshot is optional.
  }) {
    if (invoiceId.isEmpty) {
      throw Exception('Invoice ID cannot be empty.');
    }
    return repository.notifyPayment(invoiceId, proofUrl);
  }
}
