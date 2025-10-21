// lib/features/customer_dashboard/presentation/screens/billing_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/providers/customer_dashboard_provider.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/invoice.dart';
import 'package:image_picker/image_picker.dart';

class BillingScreen extends ConsumerStatefulWidget {
  final Membership membership;

  const BillingScreen({super.key, required this.membership});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  @override
  void initState() {
    super.initState();
    // Load invoices on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerDashboardProvider.notifier).loadInvoices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing & Payments'),
      ),
      body: state.isLoading && state.invoices.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.invoices.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(customerDashboardProvider.notifier)
                      .loadInvoices(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.invoices.length,
                    itemBuilder: (context, index) {
                      final invoice = state.invoices[index];
                      return _buildInvoiceCard(invoice);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'No Invoices Yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Your invoices will appear here',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.periodDisplay,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Generated on ${DateFormat('dd MMM yyyy').format(invoice.generatedDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(invoice.status),
              ],
            ),
            const Divider(height: 24),

            // Amount details
            _buildAmountRow('Base Amount', invoice.baseAmount),
            _buildAmountRow('Rebate', -invoice.rebateAmount,
                color: Colors.green),
            const Divider(height: 16),
            _buildAmountRow(
              'Final Amount',
              invoice.finalAmount,
              isBold: true,
              fontSize: 18,
            ),
            const SizedBox(height: 16),

            // Attendance info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Days Present', invoice.daysPresent),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey.shade300,
                  ),
                  _buildStatItem('Total Days', invoice.totalDays),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey.shade300,
                  ),
                  _buildStatItem(
                    'Attendance',
                    '${invoice.attendancePercentage.toStringAsFixed(1)}%',
                  ),
                ],
              ),
            ),

            // Action buttons
            if (invoice.isPending) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _uploadPaymentProof(invoice.id),
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload Payment Proof'),
                ),
              ),
            ],

            if (invoice.isPaid) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pending,
                        color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Awaiting manager approval',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (invoice.isRejected && invoice.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Rejected',
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reason: ${invoice.rejectionReason}',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _uploadPaymentProof(invoice.id),
                  icon: const Icon(Icons.upload),
                  label: const Text('Re-upload Payment Proof'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        icon = Icons.pending;
        break;
      case 'paid':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade900;
        icon = Icons.schedule;
        break;
      case 'approved':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade900;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    double amount, {
    Color? color,
    bool isBold = false,
    double fontSize = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, dynamic value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Future<void> _uploadPaymentProof(String invoiceId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Upload payment proof
    await ref
        .read(customerDashboardProvider.notifier)
        .notifyPayment(invoiceId, image.path);

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    final state = ref.read(customerDashboardProvider);
    if (state.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment proof uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
