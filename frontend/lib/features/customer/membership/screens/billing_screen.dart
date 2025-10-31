// lib/features/customer/membership/screens/billing_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/billing_providers.dart';
import '../repositories/billing_repository.dart';

class BillingScreen extends ConsumerWidget {
  final String membershipId;
  const BillingScreen({super.key, required this.membershipId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(myBillsProvider(membershipId));

    return Scaffold(
      appBar: AppBar(title: const Text('Billing History')),
      body: bills.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppTheme.primaryOrange),
          ),
        ),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: AppTheme.errorRed),
              const SizedBox(height: 16),
              Text('Failed to load bills',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(myBillsProvider(membershipId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No bills yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppTheme.primaryOrange,
            onRefresh: () async {
              ref.invalidate(myBillsProvider(membershipId));
              await ref.read(myBillsProvider(membershipId).future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) => _BillCard(
                bill: list[index] as Map<String, dynamic>,
                onPay: () => _showPaymentDialog(
                    context, ref, list[index] as Map<String, dynamic>),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPaymentDialog(
      BuildContext context, WidgetRef ref, Map<String, dynamic> bill) {
    File? selectedImage;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pay Bill',
                      style: Theme.of(context).textTheme.headlineSmall),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('Amount to Pay',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Text(
                      '₹${(bill['totalAmount'] ?? 0).toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppTheme.primaryOrange,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Pay via UPI or Bank Transfer, then upload payment proof:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (selectedImage != null)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(selectedImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined,
                            size: 48, color: AppTheme.textSecondary),
                        SizedBox(height: 8),
                        Text('No image selected'),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final img =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (img != null) {
                    setModalState(() => selectedImage = File(img.path));
                  }
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Payment Proof'),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Submit for Approval',
                onPressed: selectedImage != null
                    ? () async {
                        setModalState(() => isUploading = true);
                        try {
                          await ref
                              .read(billingRepositoryProvider)
                              .submitPaymentProof(
                                billId: bill['_id'] as String,
                                file: selectedImage!,
                              );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Payment proof submitted successfully'),
                                backgroundColor: AppTheme.successGreen,
                              ),
                            );
                            ref.invalidate(myBillsProvider(membershipId));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Upload failed: ${e.toString()}'),
                                backgroundColor: AppTheme.errorRed,
                              ),
                            );
                          }
                        } finally {
                          setModalState(() => isUploading = false);
                        }
                      }
                    : null,
                isLoading: isUploading,
                icon: Icons.check,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final Map<String, dynamic> bill;
  final VoidCallback onPay;
  const _BillCard({required this.bill, required this.onPay});

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM').format(
      DateTime(bill['year'], bill['month']),
    );
    final status = bill['status'] as String;
    final statusColor = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$monthName ${bill['year']}',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Bill ID: ${bill['_id']?.substring(0, 8) ?? 'N/A'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildBillRow(context, 'Base Amount', bill['baseAmount'] ?? 0),
            const SizedBox(height: 8),
            _buildBillRow(context, 'Rebate', -(bill['rebateAmount'] ?? 0),
                isNegative: true),
            const Divider(height: 16),
            _buildBillRow(context, 'Total Amount', bill['totalAmount'] ?? 0,
                isTotal: true),
            if (status == 'Due') ...[
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Pay Now',
                onPressed: onPay,
                icon: Icons.payment,
              ),
            ],
            if (status == 'Pending Approval') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pending_outlined,
                        color: AppTheme.warningYellow, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Payment proof submitted. Awaiting manager approval.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.warningYellow,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Paid':
        return AppTheme.successGreen;
      case 'Pending Approval':
        return AppTheme.warningYellow;
      case 'Due':
        return AppTheme.errorRed;
      default:
        return AppTheme.textSecondary;
    }
  }

  Widget _buildBillRow(BuildContext context, String label, num amount,
      {bool isNegative = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)
              : Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          '${isNegative ? '-' : ''}₹${amount.abs().toStringAsFixed(0)}',
          style: isTotal
              ? Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryOrange,
                    fontWeight: FontWeight.bold,
                  )
              : Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isNegative ? AppTheme.successGreen : null,
                  ),
        ),
      ],
    );
  }
}
