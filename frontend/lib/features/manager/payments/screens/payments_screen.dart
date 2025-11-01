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

  // single, stable filter used by the family provider
  late PaymentsHistoryFilter _filter;

  // local UI selections (kept in sync with _filter)
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

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingApprovalsProvider);
    final history = ref.watch(paymentsHistoryProvider(_filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryOrange,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryOrange,
          tabs: const [
            Tab(text: 'Due Payments'),
            Tab(text: 'Pending Approvals'),
            Tab(text: 'Payment History'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_done_outlined),
            tooltip: 'Bulk Approve',
            onPressed: () => _bulkApprove(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // invalidate all three tabs once
              ref.invalidate(dueBillsProvider);
              ref.invalidate(pendingApprovalsProvider);
              ref.invalidate(paymentsHistoryProvider(_filter));
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Dues
          ref.watch(dueBillsProvider).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => _ErrorRetry(
                  message: 'Failed to load dues',
                  detail: e.toString(),
                  onRetry: () => ref.invalidate(dueBillsProvider),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return const _EmptyState(message: 'No dues found');
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(dueBillsProvider);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (context, i) => _HistoryBillTile(
                          bill: list[i] as Map<String, dynamic>),
                    ),
                  );
                },
              ),

          // Pending approvals
          pending.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.primaryOrange),
              ),
            ),
            error: (e, st) => _ErrorRetry(
              message: 'Failed to load pending approvals',
              detail: e.toString(),
              onRetry: () => ref.invalidate(pendingApprovalsProvider),
            ),
            data: (list) {
              if (list.isEmpty) {
                return const _EmptyState(
                    message: 'No pending payment approvals');
              }
              return RefreshIndicator(
                color: AppTheme.primaryOrange,
                onRefresh: () async {
                  ref.invalidate(pendingApprovalsProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) => _PendingPaymentCard(
                    bill: list[index] as Map<String, dynamic>,
                    onApprove: (id) => _approvePayment(context, id),
                    onReject: (id) => _rejectPayment(context, id),
                    onViewProof: (bill) => _showPaymentProof(context, bill),
                  ),
                ),
              );
            },
          ),

          // History with filters (uses stable _filter)
          Column(
            children: [
              _HistoryFilters(
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
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation(AppTheme.primaryOrange),
                    ),
                  ),
                  error: (e, st) => _ErrorRetry(
                    message: 'Failed to load history',
                    detail: e.toString(),
                    onRetry: () =>
                        ref.invalidate(paymentsHistoryProvider(_filter)),
                  ),
                  data: (list) {
                    if (list.isEmpty) {
                      return const _EmptyState(message: 'No records found');
                    }
                    return RefreshIndicator(
                      color: AppTheme.primaryOrange,
                      onRefresh: () async {
                        ref.invalidate(paymentsHistoryProvider(_filter));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        itemBuilder: (context, index) => _HistoryBillTile(
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
    );
  }

  Future _approvePayment(BuildContext context, String billId) async {
    try {
      await ref.read(managerPaymentsRepositoryProvider).approvePayment(billId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Payment approved'),
            backgroundColor: AppTheme.successGreen),
      );
      ref.invalidate(pendingApprovalsProvider);
      ref.invalidate(paymentsHistoryProvider(_filter));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed: $e'), backgroundColor: AppTheme.errorRed),
      );
    }
  }

  Future<void> _rejectPayment(BuildContext context, String billId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Payment'),
        content: const Text('Are you sure you want to reject this payment?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(managerPaymentsRepositoryProvider).rejectPayment(billId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Payment rejected'),
          backgroundColor: AppTheme.warningYellow));
      ref.invalidate(pendingApprovalsProvider);
      ref.invalidate(paymentsHistoryProvider(_filter));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'), backgroundColor: AppTheme.errorRed));
    }
  }

  Future<void> _bulkApprove(BuildContext context) async {
    // Minimal UX: confirm and approve all visible pending (extend with selections if needed)
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve All Pending'),
        content: const Text('Approve all currently pending payments?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Approve')),
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
        if (id != null)
          await ref.read(managerPaymentsRepositoryProvider).approvePayment(id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All pending payments approved')));
      ref.invalidate(pendingApprovalsProvider);
      ref.invalidate(paymentsHistoryProvider(_filter));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Bulk approve failed: $e'),
          backgroundColor: AppTheme.errorRed));
    }
  }

  Future _showPaymentProof(BuildContext context, Map bill) async {
    try {
      final repo = ref.read(managerPaymentsRepositoryProvider);
      final url =
          await repo.getPaymentProofUrl(Map<String, dynamic>.from(bill));
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
                    Text('Payment Proof',
                        style: Theme.of(context).textTheme.titleLarge),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              Container(
                height: 420,
                color: Colors.grey[100],
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
                            return const Center(
                                child: CircularProgressIndicator());
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
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment Proof'),
          content: Text('Failed to load proof: $e'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'))
          ],
        ),
      );
    }
  }
}

class _PendingPaymentCard extends StatelessWidget {
  final Map<String, dynamic> bill;
  final Future<void> Function(String billId) onApprove;
  final Future<void> Function(String billId) onReject;
  final Future<void> Function(Map<String, dynamic> bill) onViewProof;

  const _PendingPaymentCard({
    required this.bill,
    required this.onApprove,
    required this.onReject,
    required this.onViewProof,
  });

  @override
  Widget build(BuildContext context) {
    final user =
        bill['user'] as Map<String, dynamic>?; // expected when server populates
    final userName = user?['name'] ?? bill['userName'] ?? 'Unknown';
    final userPhone = user?['phone'] ?? bill['userPhone'] ?? 'N/A';
    final month = bill['month'] as int? ?? 0;
    final year = bill['year'] as int? ?? 0;
    final amount = (bill['totalAmount'] ?? bill['amount'] ?? 0) as num;
    final monthName =
        month > 0 ? DateFormat('MMMM').format(DateTime(year, month)) : '-';
    final billId = bill['_id'] as String? ?? bill['id'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: AppTheme.warningYellow.withOpacity(0.1),
              child: Text(
                (userName as String).isNotEmpty
                    ? userName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: AppTheme.warningYellow, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(userPhone,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.textSecondary)),
                  ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.warningYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.warningYellow),
              ),
              child: const Text('Pending Approval',
                  style: TextStyle(
                      color: AppTheme.warningYellow,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          const Divider(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Billing Period',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Text('$monthName $year',
                  style: Theme.of(context).textTheme.titleMedium),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Amount',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Text('₹${amount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.bold)),
            ]),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onViewProof(bill),
                icon: const Icon(Icons.visibility),
                label: const Text('View Proof'),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: billId.isNotEmpty ? () => onReject(billId) : null,
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorRed,
                    side: const BorderSide(color: AppTheme.errorRed)),
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: billId.isNotEmpty ? () => onApprove(billId) : null,
                child: const Text('Approve'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _HistoryBillTile extends StatelessWidget {
  final Map<String, dynamic> bill;
  const _HistoryBillTile({required this.bill});

  @override
  Widget build(BuildContext context) {
    final user = bill['user'] as Map<String, dynamic>?;
    final userName = user?['name'] ?? bill['userName'] ?? 'Unknown';
    final month = bill['month'] as int? ?? 0;
    final year = bill['year'] as int? ?? 0;
    final status = bill['status'] as String? ?? 'Unknown';
    final amount = (bill['totalAmount'] ?? bill['amount'] ?? 0) as num;
    final monthName =
        month > 0 ? DateFormat('MMMM').format(DateTime(year, month)) : '-';

    final color = () {
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
    }();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Text(
            (userName as String).isNotEmpty ? userName[0].toUpperCase() : '?',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(userName),
        subtitle: Text('$monthName $year'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₹${amount.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryOrange,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4)),
              child: Text(status,
                  style: TextStyle(
                      color: color, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryFilters extends StatefulWidget {
  final String? status;
  final int? month;
  final int? year;
  final void Function(String? status, int? month, int? year, String? query)
      onChanged;
  const _HistoryFilters(
      {required this.status,
      required this.month,
      required this.year,
      required this.onChanged});

  @override
  State<_HistoryFilters> createState() => _HistoryFiltersState();
}

class _HistoryFiltersState extends State<_HistoryFilters> {
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: const BoxDecoration(color: AppTheme.surfaceColor),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                  DropdownMenuItem(
                      value: 'Pending Approval',
                      child: Text('Pending Approval')),
                  DropdownMenuItem(value: 'Due', child: Text('Due')),
                ],
                onChanged: (v) => setState(() => _status = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _month,
                decoration: const InputDecoration(labelText: 'Month'),
                items: List.generate(12, (i) => i + 1)
                    .map((m) => DropdownMenuItem(
                        value: m,
                        child:
                            Text(DateFormat('MMM').format(DateTime(2000, m)))))
                    .toList(),
                onChanged: (v) => setState(() => _month = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _year,
                decoration: const InputDecoration(labelText: 'Year'),
                items: years
                    .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                    .toList(),
                onChanged: (v) => setState(() => _year = v),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Search by name/phone',
                  prefixIcon: Icon(Icons.search),
                ),
                onSubmitted: (_) => _apply(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
                onPressed: _apply,
                icon: const Icon(Icons.filter_alt),
                label: const Text('Apply')),
          ]),
        ],
      ),
    );
  }

  void _apply() {
    widget.onChanged(_status, _month, _year,
        _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim());
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.payment_outlined,
            size: 80, color: AppTheme.textSecondary.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text(message,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppTheme.textSecondary)),
      ]),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final String detail;
  final VoidCallback onRetry;
  const _ErrorRetry(
      {required this.message, required this.detail, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(detail,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry')),
        ]),
      ),
    );
  }
}

class _ProofError extends StatelessWidget {
  const _ProofError();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_not_supported, size: 64),
        SizedBox(height: 8),
        Text('Failed to load image'),
      ],
    );
  }
}
