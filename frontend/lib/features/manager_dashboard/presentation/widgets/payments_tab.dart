// lib/features/manager_dashboard/presentation/widgets/payments_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/providers/manager_dashboard_provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PaymentsTab extends ConsumerWidget {
  const PaymentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(managerDashboardProvider);

    if (dashboardState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dashboardState.paymentApprovals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
            SizedBox(height: 16),
            Text('No pending approvals',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dashboardState.paymentApprovals.length,
      itemBuilder: (context, index) {
        final approval = dashboardState.paymentApprovals[index];
        final monthName =
            DateFormat.MMMM().format(DateTime(approval.year, approval.month));

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: approval.customerPhoto != null
                ? CircleAvatar(
                    backgroundImage: NetworkImage(approval.customerPhoto!))
                : const CircleAvatar(child: Icon(Icons.person)),
            title: Text(approval.customerName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
                '$monthName ${approval.year} - ₹${approval.amount.toStringAsFixed(0)}'),
            children: [
              if (approval.proofUrl != null) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Payment Proof:',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              child: CachedNetworkImage(
                                imageUrl: approval.proofUrl!,
                                placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: approval.proofUrl!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await ref
                                .read(managerDashboardProvider.notifier)
                                .rejectPayment(approval.invoiceId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Payment rejected'),
                                    backgroundColor: Colors.red),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          try {
                            await ref
                                .read(managerDashboardProvider.notifier)
                                .approvePayment(approval.invoiceId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Payment approved!'),
                                    backgroundColor: Colors.green),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
