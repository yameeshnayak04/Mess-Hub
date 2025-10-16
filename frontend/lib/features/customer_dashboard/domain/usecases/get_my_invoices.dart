// lib/features/customer_dashboard/domain/usecases/get_my_invoices.dart

import 'package:mess_management_system/features/customer_dashboard/domain/entities/invoice.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/repositories/customer_repository.dart';

class GetMyInvoices {
  final CustomerRepository repository;

  GetMyInvoices(this.repository);

  // Use case for fetching all invoices for the logged-in user.
  Future<List<Invoice>> call() {
    return repository.getMyInvoices();
  }
}
