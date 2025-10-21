// lib/features/manager_dashboard/domain/usecases/approve_payment.dart

import 'package:mess_management_system/features/manager_dashboard/domain/repositories/manager_repository.dart';

class ApprovePayment {
  final ManagerRepository repository;

  ApprovePayment(this.repository);

  Future<void> call(String invoiceId) {
    return repository.approvePayment(invoiceId);
  }
}
