// lib/features/manager_dashboard/presentation/tabs/home_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/manager_dashboard_provider.dart';
import '../widgets/stats_card.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    return stats.when(
      data: (data) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _card(context, ref, 'On Leave', Icons.event_busy,
                    data['onLeave']?.toString() ?? '0', 'onLeave'),
                _card(
                    context,
                    ref,
                    'Lunch Present',
                    Icons.lunch_dining,
                    data['lunchPresent']?.toString() ?? '0',
                    'attendance:Lunch'),
                _card(
                    context,
                    ref,
                    'Dinner Present',
                    Icons.dinner_dining,
                    data['dinnerPresent']?.toString() ?? '0',
                    'attendance:Dinner'),
                _card(context, ref, 'Payment Approvals', Icons.receipt_long,
                    data['pendingApprovals']?.toString() ?? '0', 'approvals'),
              ],
            ),
            const SizedBox(height: 24),
            Text('Today', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.payments),
                title:
                    Text('Revenue this month: ₹${data['monthlyRevenue'] ?? 0}'),
                subtitle: const Text('Includes paid invoices this month'),
              ),
            ),
          ]),
        );
      },
      error: (e, _) => Center(child: Text(e.toString())),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _card(BuildContext context, WidgetRef ref, String title, IconData icon,
      String value, String type) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => ContributorsSheet(type: type),
      ),
      child: StatsCard(title: title, value: value, icon: icon),
    );
  }
}

class ContributorsSheet extends ConsumerWidget {
  final String type;
  const ContributorsSheet({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardContributorsProvider(type));
    final title = switch (type) {
      'onLeave' => 'Members on Leave (Today)',
      'attendance:Lunch' => 'Lunch Attendance (Today)',
      'attendance:Dinner' => 'Dinner Attendance (Today)',
      'approvals' => 'Pending Payment Approvals',
      _ => 'Details',
    };
    return DraggableScrollableSheet(
      expand: false,
      builder: (_, scroll) => Material(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2))),
            Padding(
                padding: const EdgeInsets.all(12),
                child: Text(title,
                    style: Theme.of(context).textTheme.titleMedium)),
            Expanded(
              child: async.when(
                data: (rows) => ListView.builder(
                  controller: scroll,
                  itemCount: rows.length,
                  itemBuilder: (_, i) {
                    final r = rows[i] as Map<String, dynamic>;
                    // Approvals: invoice with membership->customer
                    if (type == 'approvals') {
                      final membership =
                          r['membership'] as Map<String, dynamic>?;
                      final customer =
                          membership?['customer'] as Map<String, dynamic>?;
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(customer?['name'] ?? 'Member'),
                        subtitle: Text('Requested: ${r['createdAt'] ?? ''}'),
                        trailing: const Icon(Icons.chevron_right),
                      );
                    }
                    // Leaves or Attendance
                    final membership = r['membership'] as Map<String, dynamic>?;
                    final customer =
                        membership?['customer'] as Map<String, dynamic>?;
                    final subtitle = type == 'onLeave'
                        ? '${r['startDate'] ?? ''} → ${r['endDate'] ?? ''}'
                        : (r['mealType'] ?? '');
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(customer?['name'] ?? 'Member'),
                      subtitle: Text(subtitle),
                      trailing: Text(customer?['phone'] ?? ''),
                    );
                  },
                ),
                loading: () => const Center(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator())),
                error: (e, _) => Center(
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(e.toString()))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
