// lib/features/manager_dashboard/presentation/tabs/payments_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/manager_dashboard_provider.dart';

class PaymentsTab extends ConsumerWidget {
  const PaymentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvals = ref.watch(dashboardContributorsProvider('approvals'));
    return approvals.when(
      data: (rows) => ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final inv = rows[i] as Map<String, dynamic>;
          final membership = inv['membership'] as Map<String, dynamic>?;
          final customer = membership?['customer'] as Map<String, dynamic>?;
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(customer?['name'] ?? 'Member'),
            subtitle: Text(
                '₹${inv['amount']} • ${inv['month']}/${inv['year']} • ${inv['status']}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () {
                  final url = inv['proofUrl']?.toString() ?? '';
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Submitted: ${inv['createdAt'] ?? ''}'),
                              const SizedBox(height: 8),
                              if (url.isEmpty)
                                const Text('No proof uploaded')
                              else
                                AspectRatio(
                                    aspectRatio: 3 / 4,
                                    child:
                                        Image.network(url, fit: BoxFit.cover)),
                            ]),
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () async {
                  await ref.read(updateInvoiceStatusProvider({
                    'invoiceId': inv['_id'] as String,
                    'status': 'rejected',
                    'rejectionReason': 'Insufficient proof',
                  }).future);
                  ref.invalidate(dashboardContributorsProvider);
                },
              ),
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () async {
                  await ref.read(updateInvoiceStatusProvider({
                    'invoiceId': inv['_id'] as String,
                    'status': 'paid',
                  }).future);
                  ref.invalidate(dashboardContributorsProvider);
                },
              ),
            ]),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }
}
