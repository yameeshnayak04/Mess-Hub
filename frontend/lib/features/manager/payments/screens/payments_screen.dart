// lib/features/manager/billing/screens/payments_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/manager_payments_providers.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PaymentsHistoryFilter _filter;

  String? _statusFilter;
  int? _monthFilter;
  int? _yearFilter;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _filter = const PaymentsHistoryFilter(page: 1, limit: 20);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppTheme.errorRed : AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingApprovalsProvider);
    final history = ref.watch(paymentsHistoryProvider(_filter));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryOrange,
                    AppTheme.secondaryOrange,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryOrange.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payments',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage payments & approvals',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.download_done_outlined,
                                color: Colors.white),
                            onPressed: () => _bulkApprove(context),
                            tooltip: 'Bulk Approve',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon:
                                const Icon(Icons.refresh, color: Colors.white),
                            onPressed: () {
                              ref.invalidate(dueBillsProvider);
                              ref.invalidate(pendingApprovalsProvider);
                              ref.invalidate(paymentsHistoryProvider(_filter));
                              _showSnackBar('Refreshing...');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withOpacity(0.6),
                      indicator: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(text: 'Due'),
                        Tab(text: 'Pending'),
                        Tab(text: 'History'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Due Payments Tab
                  ref.watch(dueBillsProvider).when(
                        loading: () =>
                            _buildLoadingState('Loading due payments...'),
                        error: (e, st) => _ErrorRetry(
                          message: 'Failed to load due payments',
                          detail: e.toString(),
                          onRetry: () => ref.invalidate(dueBillsProvider),
                        ),
                        data: (list) {
                          if (list.isEmpty) {
                            return _buildEmptyState(
                              'No Due Payments',
                              'All payments are up to date',
                              Icons.payments_outlined,
                            );
                          }
                          return RefreshIndicator(
                            color: AppTheme.primaryOrange,
                            onRefresh: () async {
                              ref.invalidate(dueBillsProvider);
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: list.length,
                              itemBuilder: (context, i) => _ModernBillCard(
                                bill: list[i] as Map<String, dynamic>,
                              ),
                            ),
                          );
                        },
                      ),

                  // Pending Approvals Tab
                  pending.when(
                    loading: () =>
                        _buildLoadingState('Loading pending approvals...'),
                    error: (e, st) => _ErrorRetry(
                      message: 'Failed to load pending approvals',
                      detail: e.toString(),
                      onRetry: () => ref.invalidate(pendingApprovalsProvider),
                    ),
                    data: (list) {
                      if (list.isEmpty) {
                        return _buildEmptyState(
                          'No Pending Approvals',
                          'All payments have been reviewed',
                          Icons.done_all,
                        );
                      }
                      return RefreshIndicator(
                        color: AppTheme.primaryOrange,
                        onRefresh: () async {
                          ref.invalidate(pendingApprovalsProvider);
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          itemBuilder: (context, index) => _ModernPendingCard(
                            bill: list[index] as Map<String, dynamic>,
                            onApprove: (id) => _approvePayment(context, id),
                            onReject: (id) => _rejectPayment(context, id),
                            onViewProof: (bill) =>
                                _showPaymentProof(context, bill),
                          ),
                        ),
                      );
                    },
                  ),

                  // History Tab
                  Column(
                    children: [
                      _ModernHistoryFilters(
                        status: _statusFilter,
                        month: _monthFilter,
                        year: _yearFilter,
                        onChanged: (status, month, year, query) {
                          setState(() {
                            _statusFilter = status;
                            _monthFilter = month;
                            _yearFilter = year;
                            _searchQuery = query;
                            _filter = _filter.copyWith(
                              status: status,
                              month: month,
                              year: year,
                              query: query,
                              page: 1,
                            );
                          });
                          ref.invalidate(paymentsHistoryProvider(_filter));
                        },
                      ),
                      Expanded(
                        child: history.when(
                          loading: () =>
                              _buildLoadingState('Loading history...'),
                          error: (e, st) => _ErrorRetry(
                            message: 'Failed to load payment history',
                            detail: e.toString(),
                            onRetry: () => ref
                                .invalidate(paymentsHistoryProvider(_filter)),
                          ),
                          data: (list) {
                            if (list.isEmpty) {
                              return _buildEmptyState(
                                'No Records Found',
                                _searchQuery != null
                                    ? 'Try adjusting your filters'
                                    : 'No payment history available',
                                Icons.history,
                              );
                            }
                            return RefreshIndicator(
                              color: AppTheme.primaryOrange,
                              onRefresh: () async {
                                ref.invalidate(
                                    paymentsHistoryProvider(_filter));
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: list.length,
                                itemBuilder: (context, index) =>
                                    _ModernBillCard(
                                  bill: list[index] as Map<String, dynamic>,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryOrange.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: AppTheme.primaryOrange,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: AppTheme.primaryOrange.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future _approvePayment(BuildContext context, String billId) async {
    try {
      await ref.read(managerPaymentsRepositoryProvider).approvePayment(billId);
      if (!context.mounted) return;
      _showSnackBar('Payment approved successfully! ✓');
      ref.invalidate(pendingApprovalsProvider);
      ref.invalidate(paymentsHistoryProvider(_filter));
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar('Failed: ${e.toString().replaceAll('Exception: ', '')}',
          isError: true);
    }
  }

  Future<void> _rejectPayment(BuildContext context, String billId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.errorRed),
            ),
            const SizedBox(width: 12),
            const Text('Reject Payment'),
          ],
        ),
        content: const Text(
            'Are you sure you want to reject this payment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(managerPaymentsRepositoryProvider).rejectPayment(billId);
      if (!context.mounted) return;
      _showSnackBar('Payment rejected');
      ref.invalidate(pendingApprovalsProvider);
      ref.invalidate(paymentsHistoryProvider(_filter));
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar('Failed: ${e.toString().replaceAll('Exception: ', '')}',
          isError: true);
    }
  }

  Future<void> _bulkApprove(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.done_all, color: AppTheme.successGreen),
            ),
            const SizedBox(width: 12),
            const Text('Bulk Approve'),
          ],
        ),
        content: const Text('Approve all pending payments at once?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve All'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final pending = await ref
          .read(managerPaymentsRepositoryProvider)
          .getPendingApprovals();
      for (final b in pending) {
        final id = (b as Map<String, dynamic>)['_id'] as String?;
        if (id != null) {
          await ref.read(managerPaymentsRepositoryProvider).approvePayment(id);
        }
      }
      if (!context.mounted) return;
      _showSnackBar('All pending payments approved! 🎉');
      ref.invalidate(pendingApprovalsProvider);
      ref.invalidate(paymentsHistoryProvider(_filter));
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(
          'Bulk approve failed: ${e.toString().replaceAll('Exception: ', '')}',
          isError: true);
    }
  }

  Future _showPaymentProof(BuildContext context, Map bill) async {
    try {
      final repo = ref.read(managerPaymentsRepositoryProvider);
      final url =
          await repo.getPaymentProofUrl(Map<String, dynamic>.from(bill));

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryOrange,
                      AppTheme.secondaryOrange,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.receipt_long, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          'Payment Proof',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                ),
                alignment: Alignment.center,
                child: (url != null)
                    ? InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4,
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const _ProofError(),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                  color: AppTheme.primaryOrange,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading image...',
                                  style:
                                      TextStyle(color: AppTheme.textSecondary),
                                ),
                              ],
                            );
                          },
                        ),
                      )
                    : const _ProofError(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Payment Proof'),
          content: Text('Failed to load proof: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}

// Modern Bill Card
class _ModernBillCard extends StatelessWidget {
  final Map<String, dynamic> bill;

  const _ModernBillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    final user = bill['user'] as Map<String, dynamic>?;
    final userName = user?['name'] ?? bill['userName'] ?? 'Unknown';
    final userPhone = user?['phone'] ?? bill['userPhone'] ?? 'N/A';
    final month = bill['month'] as int? ?? 0;
    final year = bill['year'] as int? ?? 0;
    final status = bill['status'] as String? ?? 'Unknown';
    final amount = (bill['totalAmount'] ?? bill['amount'] ?? 0) as num;
    final monthName =
        month > 0 ? DateFormat('MMMM').format(DateTime(year, month)) : '-';

    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor, statusColor.withOpacity(0.7)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  (userName as String).isNotEmpty
                      ? userName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone,
                          size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        userPhone,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$monthName $year',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Paid':
        return Icons.check_circle;
      case 'Pending Approval':
        return Icons.pending;
      case 'Due':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }
}

// Modern Pending Card
class _ModernPendingCard extends StatelessWidget {
  final Map<String, dynamic> bill;
  final Future<void> Function(String billId) onApprove;
  final Future<void> Function(String billId) onReject;
  final Future<void> Function(Map<String, dynamic> bill) onViewProof;

  const _ModernPendingCard({
    required this.bill,
    required this.onApprove,
    required this.onReject,
    required this.onViewProof,
  });

  @override
  Widget build(BuildContext context) {
    final user = bill['user'] as Map<String, dynamic>?;
    final userName = user?['name'] ?? bill['userName'] ?? 'Unknown';
    final userPhone = user?['phone'] ?? bill['userPhone'] ?? 'N/A';
    final month = bill['month'] as int? ?? 0;
    final year = bill['year'] as int? ?? 0;
    final amount = (bill['totalAmount'] ?? bill['amount'] ?? 0) as num;
    final monthName =
        month > 0 ? DateFormat('MMMM').format(DateTime(year, month)) : '-';
    final billId = bill['_id'] as String? ?? bill['id'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.warningYellow.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.warningYellow,
                        AppTheme.warningYellow.withOpacity(0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.warningYellow.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (userName as String).isNotEmpty
                          ? userName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone,
                              size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            userPhone,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.warningYellow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.warningYellow.withOpacity(0.5),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pending,
                          color: AppTheme.warningYellow, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Pending',
                        style: TextStyle(
                          color: AppTheme.warningYellow,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Period',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$monthName $year',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Amount',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.infoBlue,
                    AppTheme.infoBlue.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.infoBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onViewProof(bill),
                  borderRadius: BorderRadius.circular(12),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.visibility, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'View Payment Proof',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.errorRed.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap:
                            billId.isNotEmpty ? () => onReject(billId) : null,
                        borderRadius: BorderRadius.circular(12),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close,
                                  color: AppTheme.errorRed, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Reject',
                                style: TextStyle(
                                  color: AppTheme.errorRed,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.successGreen,
                          AppTheme.successGreen.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.successGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap:
                            billId.isNotEmpty ? () => onApprove(billId) : null,
                        borderRadius: BorderRadius.circular(12),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Approve',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Modern History Filters
class _ModernHistoryFilters extends StatefulWidget {
  final String? status;
  final int? month;
  final int? year;
  final void Function(String? status, int? month, int? year, String? query)
      onChanged;

  const _ModernHistoryFilters({
    required this.status,
    required this.month,
    required this.year,
    required this.onChanged,
  });

  @override
  State<_ModernHistoryFilters> createState() => _ModernHistoryFiltersState();
}

class _ModernHistoryFiltersState extends State<_ModernHistoryFilters> {
  late String? _status;
  late int? _month;
  late int? _year;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _status = widget.status;
    _month = widget.month;
    _year = widget.year ?? DateTime.now().year;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(4, (i) => DateTime.now().year - i);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.filter_list,
                  color: AppTheme.primaryOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.borderColor.withOpacity(0.3),
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: null, child: Text('All Statuses')),
                      DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                      DropdownMenuItem(
                          value: 'Pending Approval', child: Text('Pending')),
                      DropdownMenuItem(value: 'Due', child: Text('Due')),
                    ],
                    onChanged: (v) => setState(() => _status = v),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.borderColor.withOpacity(0.3),
                    ),
                  ),
                  child: DropdownButtonFormField<int>(
                    value: _month,
                    decoration: const InputDecoration(
                      labelText: 'Month',
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      ...List.generate(12, (i) => i + 1).map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child:
                              Text(DateFormat('MMM').format(DateTime(2000, m))),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _month = v),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.borderColor.withOpacity(0.3),
                    ),
                  ),
                  child: DropdownButtonFormField<int>(
                    value: _year,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: years
                        .map((y) =>
                            DropdownMenuItem(value: y, child: Text('$y')))
                        .toList(),
                    onChanged: (v) => setState(() => _year = v),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.borderColor.withOpacity(0.3),
                    ),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Search by name or phone',
                      prefixIcon:
                          Icon(Icons.search, color: AppTheme.primaryOrange),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _apply(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryOrange,
                      AppTheme.secondaryOrange,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryOrange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _apply,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Apply',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _apply() {
    widget.onChanged(
      _status,
      _month,
      _year,
      _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
    );
  }
}

// Error Retry Widget
class _ErrorRetry extends StatelessWidget {
  final String message;
  final String detail;
  final VoidCallback onRetry;

  const _ErrorRetry({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              detail,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Proof Error Widget
class _ProofError extends StatelessWidget {
  const _ProofError();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.errorRed.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.image_not_supported,
            size: 64,
            color: AppTheme.errorRed,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Failed to load image',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
