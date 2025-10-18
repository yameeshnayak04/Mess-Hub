// lib/features/manager_dashboard/presentation/tabs/applications_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/providers/manager_dashboard_provider.dart';

class ApplicationsTab extends ConsumerWidget {
  const ApplicationsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(managerDashboardProvider);
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(managerDashboardProvider.notifier).fetchPaymentApprovals(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.approvals.length,
        itemBuilder: (_, i) {
          final inv = state.approvals[i];
          return Card(
            child: ListTile(
              title: Text(
                  'Invoice ${inv.month}/${inv.year} • ₹${inv.amount.toStringAsFixed(0)}'),
              subtitle: Text('Status: ${inv.status}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline,
                        color: Colors.green),
                    onPressed: () => ref
                        .read(managerDashboardProvider.notifier)
                        .updateInvoiceStatus(inv.id, 'paid'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    onPressed: () async {
                      final reason = await _promptRejection(context);
                      if (reason != null) {
                        ref
                            .read(managerDashboardProvider.notifier)
                            .updateInvoiceStatus(inv.id, 'rejected',
                                reason: reason);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String?> _promptRejection(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject payment'),
        content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Reason (optional)')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Reject')),
        ],
      ),
    );
  }
}
