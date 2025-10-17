// lib/features/customer_dashboard/presentation/screens/billing_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/invoice.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/providers/membership_provider.dart';

class BillingScreen extends ConsumerStatefulWidget {
  final String membershipId;
  const BillingScreen({super.key, required this.membershipId});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch the invoice data as soon as the screen loads.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerDashboardProvider.notifier).fetchMyInvoices();
    });
  }

  // Handles the "I Have Paid" button press for an invoice.
  Future<void> _handlePaymentNotification(String invoiceId) async {
    final notifier = ref.read(customerDashboardProvider.notifier);
    try {
      // In a real app, you would first use image_picker to get a proofUrl.
      // For now, we pass null.
      await notifier.notifyPayment(invoiceId: invoiceId, proofUrl: null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Manager has been notified of your payment!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerDashboardProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Billing History')),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(CustomerDashboardState state) {
    if (state.isLoading && state.invoices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(child: Text('An error occurred: ${state.error}'));
    }
    if (state.invoices.isEmpty) {
      return const Center(child: Text('No billing history found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: state.invoices.length,
      itemBuilder: (context, index) {
        final invoice = state.invoices[index];
        return _InvoiceCard(
          invoice: invoice,
          onPay: () => _handlePaymentNotification(invoice.id),
          isLoading: state.isLoading,
        );
      },
    );
  }
}

// A private helper widget for displaying a single invoice card.
class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onPay;
  final bool isLoading;

  const _InvoiceCard(
      {required this.invoice, required this.onPay, required this.isLoading});

  // Helper to get color and icon based on invoice status
  (Color, IconData) _getStatusInfo(String status) {
    switch (status) {
      case 'paid':
        return (Colors.green, Icons.check_circle);
      case 'pending_approval':
        return (Colors.orange, Icons.hourglass_top);
      case 'rejected':
        return (Colors.red, Icons.cancel);
      case 'due':
      default:
        return (Colors.blueGrey, Icons.info_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (statusColor, statusIcon) = _getStatusInfo(invoice.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bill for ${invoice.month}, ${invoice.year}',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${invoice.amount.toStringAsFixed(2)}',
                  style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Status: ${invoice.status.replaceAll('_', ' ').toUpperCase()}',
                  style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold, color: statusColor),
                ),
              ],
            ),
            if (invoice.status == 'due') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onPay,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3))
                      : const Text('I Have Paid, Notify Manager'),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Note: Pay the manager via UPI/cash first, then tap this button.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              )
            ]
          ],
        ),
      ),
    );
  }
}
