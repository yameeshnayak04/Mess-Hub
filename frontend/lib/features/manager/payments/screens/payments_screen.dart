import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryOrange,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryOrange,
          tabs: const [
            Tab(text: 'Pending Approvals'),
            Tab(text: 'Payment History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingApprovalsTab(),
          _buildPaymentHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildPendingApprovalsTab() {
    // Sample data - replace with actual API data
    final pendingPayments = [
      {
        'id': '1',
        'userName': 'Amit Singh',
        'userPhone': '9876543212',
        'month': 10,
        'year': 2025,
        'amount': 2800.0,
        'proofUrl': 'https://example.com/proof1.jpg',
        'submittedDate': DateTime.now().subtract(const Duration(hours: 2)),
      },
      {
        'id': '2',
        'userName': 'Sneha Patel',
        'userPhone': '9876543213',
        'month': 10,
        'year': 2025,
        'amount': 1500.0,
        'proofUrl': 'https://example.com/proof2.jpg',
        'submittedDate': DateTime.now().subtract(const Duration(hours: 5)),
      },
    ];

    if (pendingPayments.isEmpty) {
      return _buildEmptyState('No pending payment approvals');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingPayments.length,
      itemBuilder: (context, index) {
        final payment = pendingPayments[index];
        return _buildPendingPaymentCard(payment);
      },
    );
  }

  Widget _buildPaymentHistoryTab() {
    // Sample data - replace with actual API data
    final paymentHistory = [
      {
        'id': '3',
        'userName': 'Priya Sharma',
        'month': 9,
        'year': 2025,
        'amount': 2850.0,
        'status': 'Paid',
        'paidDate': DateTime.now().subtract(const Duration(days: 5)),
      },
      {
        'id': '4',
        'userName': 'Rahul Kumar',
        'month': 9,
        'year': 2025,
        'amount': 3000.0,
        'status': 'Paid',
        'paidDate': DateTime.now().subtract(const Duration(days: 10)),
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: paymentHistory.length,
      itemBuilder: (context, index) {
        final payment = paymentHistory[index];
        return _buildPaymentHistoryCard(payment);
      },
    );
  }

  Widget _buildPendingPaymentCard(Map<String, dynamic> payment) {
    final monthName = DateFormat('MMMM').format(
      DateTime(payment['year'], payment['month']),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.warningYellow.withOpacity(0.1),
                  child: Text(
                    payment['userName'][0].toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.warningYellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment['userName'],
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        payment['userPhone'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningYellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.warningYellow),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: AppTheme.warningYellow,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Billing Period',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$monthName ${payment['year']}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Amount',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${payment['amount'].toStringAsFixed(0)}',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppTheme.primaryOrange,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showPaymentProof(context, payment),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Proof'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectPayment(payment['id']),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                      side: const BorderSide(color: AppTheme.errorRed),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approvePayment(payment['id']),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistoryCard(Map<String, dynamic> payment) {
    final monthName = DateFormat('MMMM').format(
      DateTime(payment['year'], payment['month']),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.successGreen.withOpacity(0.1),
          child: Text(
            payment['userName'][0].toUpperCase(),
            style: const TextStyle(
              color: AppTheme.successGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(payment['userName']),
        subtitle: Text('$monthName ${payment['year']}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${payment['amount'].toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryOrange,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Paid',
                style: TextStyle(
                  color: AppTheme.successGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment_outlined,
            size: 80,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  void _showPaymentProof(BuildContext context, Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payment Proof',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Container(
              height: 400,
              color: Colors.grey[200],
              child: Center(
                child: Image.network(
                  payment['proofUrl'],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported, size: 64),
                        SizedBox(height: 8),
                        Text('Failed to load image'),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _approvePayment(String paymentId) {
    // API call to approve payment
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment approved successfully')),
    );
  }

  void _rejectPayment(String paymentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Payment'),
        content: const Text('Are you sure you want to reject this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // API call to reject payment
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment rejected')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
