// lib/features/manager_dashboard/presentation/screens/member_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/manager_dashboard_provider.dart';

class MemberDetailScreen extends ConsumerStatefulWidget {
  final String membershipId;
  const MemberDetailScreen({super.key, required this.membershipId});

  @override
  ConsumerState<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends ConsumerState<MemberDetailScreen> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _pickMonth() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 1, 1);
    final last = DateTime(now.year + 1, 12);
    // Simple month picker: use showDatePicker and only take month/year of the picked date
    final picked = await showDatePicker(
      context: context,
      firstDate: first,
      lastDate: last,
      initialDate: DateTime(_year, _month),
      helpText: 'Select Month',
    );
    if (picked != null) {
      setState(() {
        _year = picked.year;
        _month = picked.month;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = {
      'membershipId': widget.membershipId,
      'year': _year,
      'month': _month
    };
    final detail = ref.watch(memberDetailProvider(args));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Details'),
        actions: [
          IconButton(
              onPressed: _pickMonth, icon: const Icon(Icons.calendar_month)),
          IconButton(
            onPressed: () async {
              await ref.read(
                  runBillingProvider({'year': _year, 'month': _month}).future);
              ref.invalidate(memberDetailProvider);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Billing run completed')));
              }
            },
            icon: const Icon(Icons.payments),
            tooltip: 'Run Billing for Month',
          ),
        ],
      ),
      body: detail.when(
        data: (data) => _body(context, data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _body(BuildContext context, Map<String, dynamic> data) {
    final membership = data['membership'] as Map<String, dynamic>;
    final customer = membership['customer'] as Map<String, dynamic>?;
    final plan = membership['mealPlan'] as Map<String, dynamic>?;
    final List<dynamic> attendance = data['attendance'] as List<dynamic>;
    final List<dynamic> leaves = data['leaves'] as List<dynamic>;
    final List<dynamic> invoices = data['invoices'] as List<dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(customer?['name'] ?? 'Member'),
            subtitle: Text('Phone: ${customer?['phone'] ?? ''}'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: Text('Plan: ${plan?['name'] ?? '-'}'),
            subtitle: Text(
                'Monthly Price: ₹${plan?['price'] ?? '-'} • Rebate/Thali: ₹${plan?['perThaliRebateRate'] ?? '-'}'),
          ),
        ),
        const SizedBox(height: 12),
        Text('Attendance (${data['month']}/${data['year']})',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _attendanceGrid(attendance),
        const SizedBox(height: 12),
        Text('Leaves', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (leaves.isEmpty)
          const Text('No leaves in this period.')
        else
          ...leaves.map((l) => ListTile(
                leading: const Icon(Icons.event_busy),
                title: Text('${l['startDate'] ?? ''} → ${l['endDate'] ?? ''}'),
                subtitle: Text(
                    'Duration: ${l['duration'] ?? 0} days • Rebate: ₹${l['rebateAmount'] ?? 0}'),
              )),
        const SizedBox(height: 12),
        Text('Invoices', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...invoices.map((inv) => Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long),
                title:
                    Text('₹${inv['amount']} • ${inv['month']}/${inv['year']}'),
                subtitle: Text('Status: ${inv['status']}'),
                trailing: _invoiceActions(inv),
                onTap: () {
                  if (inv['proofUrl'] != null &&
                      (inv['proofUrl'] as String).isNotEmpty) {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => _ProofModal(
                          url: inv['proofUrl'] as String,
                          ts: inv['createdAt']?.toString() ?? ''),
                    );
                  }
                },
              ),
            )),
      ]),
    );
  }

  Widget _invoiceActions(Map<String, dynamic> inv) {
    final status = inv['status'] as String;
    if (status == 'pending_approval') {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          tooltip: 'Reject',
          onPressed: () async {
            await ref.read(updateInvoiceStatusProvider({
              'invoiceId': inv['_id'] as String,
              'status': 'rejected',
              'rejectionReason': 'Insufficient proof',
            }).future);
            ref.invalidate(memberDetailProvider);
          },
        ),
        IconButton(
          icon: const Icon(Icons.check_circle, color: Colors.green),
          tooltip: 'Approve',
          onPressed: () async {
            await ref.read(updateInvoiceStatusProvider({
              'invoiceId': inv['_id'] as String,
              'status': 'paid',
            }).future);
            ref.invalidate(memberDetailProvider);
          },
        ),
      ]);
    }
    return const SizedBox.shrink();
  }

  Widget _attendanceGrid(List<dynamic> records) {
    // records items: {date, mealType}
    // Present: record exists for meal; skips/leaves not shown in this view
    final grouped = <String, Set<String>>{};
    for (final r in records) {
      final d = (r['date'] ?? '').toString().substring(0, 10);
      (grouped[d] ??= <String>{}).add(r['mealType']?.toString() ?? '');
    }
    final days = grouped.keys.toList()..sort();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: days.map((d) {
        final meals = grouped[d]!;
        final tag = meals.contains('Lunch') && meals.contains('Dinner')
            ? 'Full'
            : meals.contains('Lunch')
                ? 'Lunch'
                : meals.contains('Dinner')
                    ? 'Dinner'
                    : '-';
        return Chip(label: Text('$d • $tag'));
      }).toList(),
    );
  }
}

class _ProofModal extends StatelessWidget {
  final String url;
  final String ts;
  const _ProofModal({required this.url, required this.ts});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.verified, color: Colors.green),
                const SizedBox(width: 8),
                const Text('Payment Proof',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(ts, style: const TextStyle(color: Colors.grey)),
              ]),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 3 / 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Center(child: Text('Unable to load proof'))),
                ),
              ),
              const SizedBox(height: 12),
            ]),
      ),
    );
  }
}
