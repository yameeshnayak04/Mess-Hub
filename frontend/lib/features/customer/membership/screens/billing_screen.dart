import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';

class BillingScreen extends ConsumerStatefulWidget {
  final String membershipId;

  const BillingScreen({
    super.key,
    required this.membershipId,
  });

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  // Sample bills data - replace with actual API data
  final List<Map<String, dynamic>> _bills = [
    {
      'id': '1',
      'month': 10,
      'year': 2025,
      'baseAmount': 3000.0,
      'rebateAmount': 200.0,
      'totalAmount': 2800.0,
      'status': 'Due',
    },
    {
      'id': '2',
      'month': 9,
      'year': 2025,
      'baseAmount': 3000.0,
      'rebateAmount': 150.0,
      'totalAmount': 2850.0,
      'status': 'Paid',
    },
    {
      'id': '3',
      'month': 8,
      'year': 2025,
      'baseAmount': 3000.0,
      'rebateAmount': 0.0,
      'totalAmount': 3000.0,
      'status': 'Paid',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing History'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bills.length,
        itemBuilder: (context, index) {
          final bill = _bills[index];
          return _buildBillCard(bill);
        },
      ),
    );
  }

  Widget _buildBillCard(Map<String, dynamic> bill) {
    final monthName = DateFormat('MMMM').format(
      DateTime(bill['year'], bill['month']),
    );
    final status = bill['status'] as String;
    Color statusColor;

    switch (status) {
      case 'Paid':
        statusColor = AppTheme.successGreen;
        break;
      case 'Pending Approval':
        statusColor = AppTheme.warningYellow;
        break;
      case 'Due':
        statusColor = AppTheme.errorRed;
        break;
      default:
        statusColor = AppTheme.textSecondary;
    }

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
                    Text(
                      '$monthName ${bill['year']}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bill ID: ${bill['id']}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
            _buildBillRow(
              context,
              'Base Amount',
              bill['baseAmount'],
            ),
            const SizedBox(height: 8),
            _buildBillRow(
              context,
              'Rebate',
              -bill['rebateAmount'],
              isNegative: true,
            ),
            const Divider(height: 16),
            _buildBillRow(
              context,
              'Total Amount',
              bill['totalAmount'],
              isTotal: true,
            ),
            if (status == 'Due') ...[
              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Pay Now',
                onPressed: () => _showPaymentDialog(context, bill),
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
                    const Icon(
                      Icons.pending_outlined,
                      color: AppTheme.warningYellow,
                      size: 20,
                    ),
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

  Widget _buildBillRow(
    BuildContext context,
    String label,
    double amount, {
    bool isNegative = false,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
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

  void _showPaymentDialog(BuildContext context, Map<String, dynamic> bill) {
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
                  Text(
                    'Pay Bill',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
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
                    Text(
                      'Amount to Pay',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${bill['totalAmount'].toStringAsFixed(0)}',
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
                        Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: AppTheme.textSecondary,
                        ),
                        SizedBox(height: 8),
                        Text('No image selected'),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    setModalState(() {
                      selectedImage = File(image.path);
                    });
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
                        // API call would go here
                        await Future.delayed(const Duration(seconds: 2));
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Payment proof submitted successfully',
                              ),
                            ),
                          );
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
