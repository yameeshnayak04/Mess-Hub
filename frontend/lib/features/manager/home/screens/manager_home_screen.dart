// lib/features/manager/dashboard/screens/manager_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mess_management_app/models/dashboard_stats.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_animation.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/widgets/member_detail_dialog.dart';
import '../../../../core/utils/constants.dart';
import '../providers/dashboard_provider.dart';

class ManagerHomeScreen extends ConsumerWidget {
  const ManagerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsState = ref.watch(dashboardStatsProvider);
    final approvals = ref.watch(pendingApprovalsProvider);
    final joinRequests = ref.watch(pendingJoinRequestsProvider);
    final todaysMenu = ref.watch(todaysMenuProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Pending Approvals',
            onPressed: () => context.go(RouteNames.managerBillingApprovals),
          ),
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            tooltip: 'Edit Menu',
            onPressed: () => context.go(RouteNames.managerMenu),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryOrange,
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(pendingApprovalsProvider);
          ref.invalidate(pendingJoinRequestsProvider);
          ref.invalidate(todaysMenuProvider);
          await ref.read(dashboardStatsProvider.notifier).refresh();
        },
        child: statsState.when(
          loading: () =>
              const LoadingAnimation(message: 'Loading dashboard...'),
          error: (e, st) => _ErrorView(
            message: 'Failed to load dashboard',
            detail: e.toString(),
            onRetry: () => ref.read(dashboardStatsProvider.notifier).refresh(),
          ),
          data: (stats) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LiveBanner(stats: stats),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Live Statistics',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.3,
                        children: [
                          StatCard(
                            title: 'Eating Now',
                            value: stats.eatingNow.toString(),
                            icon: Icons.restaurant,
                            color: AppTheme.successGreen,
                            onTap: () => _showMembersDialog(
                                context, ref, 'Members Eating Now', 'eating'),
                          ),
                          StatCard(
                            title: 'On Leave',
                            value: stats.onLeave.toString(),
                            icon: Icons.beach_access,
                            color: AppTheme.infoBlue,
                            onTap: () => _showMembersDialog(
                                context, ref, 'Members On Leave', 'leave'),
                          ),
                          StatCard(
                            title: 'Not Eating (Skipped)',
                            value: stats.notEating.toString(),
                            icon: Icons.cancel_outlined,
                            color: AppTheme.warningYellow,
                            onTap: () => _showMembersDialog(
                                context, ref, 'Members Who Skipped', 'skipped'),
                          ),
                          if (stats.dailyMembers != null)
                            StatCard(
                              title: 'Daily Members',
                              value: stats.dailyMembers.toString(),
                              icon: Icons.people,
                              color: AppTheme.primaryOrange,
                            ),
                          StatCard(
                            title: 'Total Active Members',
                            value: stats.totalActiveMembers.toString(),
                            icon: Icons.groups,
                            color: AppTheme.primaryOrange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: todaysMenu.when(
                            loading: () => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Today's Menu",
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                              ],
                            ),
                            error: (e, st) => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Today's Menu",
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                const Icon(Icons.error_outline,
                                    color: AppTheme.errorRed),
                              ],
                            ),
                            data: (menu) {
                              final lunch = (menu?['lunchItems'] as List?)
                                      ?.cast<String>() ??
                                  const <String>[];
                              final dinner = (menu?['dinnerItems'] as List?)
                                      ?.cast<String>() ??
                                  const <String>[];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Today's Menu",
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge),
                                      TextButton.icon(
                                        onPressed: () => context
                                            .push('/manager/menu-editor'),
                                        icon: const Icon(Icons.edit),
                                        label: const Text('Edit'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMenuSection(context, 'Lunch', lunch),
                                  if (lunch.isNotEmpty && dinner.isNotEmpty)
                                    const Divider(height: 24),
                                  _buildMenuSection(context, 'Dinner', dinner),
                                  if (lunch.isEmpty && dinner.isEmpty)
                                    Text(
                                      'No menu set for today',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppTheme.textSecondary),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Action Center',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      _ActionCenter(
                        approvals: approvals,
                        joinRequests: joinRequests,
                        onApprovePayment: (billId) async {
                          try {
                            await ref
                                .read(dashboardRepositoryProvider)
                                .approvePayment(billId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Payment approved'),
                                    backgroundColor: AppTheme.successGreen),
                              );
                              ref.invalidate(pendingApprovalsProvider);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Failed: $e'),
                                    backgroundColor: AppTheme.errorRed),
                              );
                            }
                          }
                        },
                        onRejectPayment: (billId) async {
                          try {
                            await ref
                                .read(dashboardRepositoryProvider)
                                .rejectPayment(billId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Payment rejected'),
                                    backgroundColor: AppTheme.warningYellow),
                              );
                              ref.invalidate(pendingApprovalsProvider);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Failed: $e'),
                                    backgroundColor: AppTheme.errorRed),
                              );
                            }
                          }
                        },
                        onApproveMember: (membershipId) async {
                          try {
                            await ref
                                .read(dashboardRepositoryProvider)
                                .approveMembership(membershipId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Member approved'),
                                    backgroundColor: AppTheme.successGreen),
                              );
                              ref.invalidate(pendingJoinRequestsProvider);
                              ref
                                  .read(dashboardStatsProvider.notifier)
                                  .refresh();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Failed: $e'),
                                    backgroundColor: AppTheme.errorRed),
                              );
                            }
                          }
                        },
                        onRejectMember: (membershipId) async {
                          try {
                            await ref
                                .read(dashboardRepositoryProvider)
                                .rejectMembership(membershipId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Member rejected'),
                                    backgroundColor: AppTheme.warningYellow),
                              );
                              ref.invalidate(pendingJoinRequestsProvider);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Failed: $e'),
                                    backgroundColor: AppTheme.errorRed),
                              );
                            }
                          }
                        },
                        onGoApprovals: () =>
                            context.go(RouteNames.managerBillingApprovals),
                        onGoMembers: () =>
                            context.go(RouteNames.managerMembers),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCenter extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> approvals;
  final AsyncValue<List<Map<String, dynamic>>> joinRequests;
  final Future<void> Function(String billId) onApprovePayment;
  final Future<void> Function(String billId) onRejectPayment;
  final Future<void> Function(String membershipId) onApproveMember;
  final Future<void> Function(String membershipId) onRejectMember;
  final VoidCallback onGoApprovals;
  final VoidCallback onGoMembers;

  const _ActionCenter({
    required this.approvals,
    required this.joinRequests,
    required this.onApprovePayment,
    required this.onRejectPayment,
    required this.onApproveMember,
    required this.onRejectMember,
    required this.onGoApprovals,
    required this.onGoMembers,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Pending Approvals',
                style: Theme.of(context).textTheme.titleMedium),
            TextButton(onPressed: onGoApprovals, child: const Text('View All')),
          ]),
          approvals.when(
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (e, st) => Text('Failed to load approvals',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.errorRed)),
            data: (list) => Column(
              children: (list.take(3)).map((bill) {
                final user = bill['user'] as Map?;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.payment, color: AppTheme.warningYellow),
                  title: Text(
                      '₹${(bill['totalAmount'] ?? 0).toString()} • ${bill['month']}/${bill['year']}'),
                  subtitle: Text(user?['name'] ?? 'Unknown'),
                  trailing: Wrap(spacing: 8, children: [
                    OutlinedButton(
                        onPressed: () => onRejectPayment(bill['_id'] as String),
                        child: const Text('Reject')),
                    ElevatedButton(
                        onPressed: () =>
                            onApprovePayment(bill['_id'] as String),
                        child: const Text('Approve')),
                  ]),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Join Requests',
                style: Theme.of(context).textTheme.titleMedium),
            TextButton(onPressed: onGoMembers, child: const Text('Manage')),
          ]),
          joinRequests.when(
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (e, st) => Text('Failed to load join requests',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.errorRed)),
            data: (list) => Column(
              children: (list.take(3)).map((member) {
                final user = member['user'] as Map?;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.person_add, color: AppTheme.infoBlue),
                  title: Text(user?['name'] ?? 'Unknown'),
                  subtitle: Text(user?['phone'] ?? 'N/A'),
                  trailing: Wrap(spacing: 8, children: [
                    OutlinedButton(
                        onPressed: () =>
                            onRejectMember(member['_id'] as String),
                        child: const Text('Reject')),
                    ElevatedButton(
                        onPressed: () =>
                            onApproveMember(member['_id'] as String),
                        child: const Text('Approve')),
                  ]),
                );
              }).toList(),
            ),
          ),
        ]),
      ),
    );
  }
}

Future<void> _showMembersDialog(
    BuildContext context, WidgetRef ref, String title, String type) async {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()));
  try {
    List<Map<String, dynamic>> data;
    switch (type) {
      case 'eating':
        data =
            await ref.read(dashboardStatsProvider.notifier).getMembersEating();
        break;
      case 'leave':
        data =
            await ref.read(dashboardStatsProvider.notifier).getMembersOnLeave();
        break;
      case 'skipped':
        data =
            await ref.read(dashboardStatsProvider.notifier).getMembersSkipped();
        break;
      default:
        data = const <Map<String, dynamic>>[];
    }
    if (!context.mounted) return;
    Navigator.pop(context);
    final members = data.map((item) {
      final user = item['user'] as Map?;
      return MemberInfo(
          name: (user?['name'] ?? 'Unknown').toString(),
          phone: (user?['phone'] ?? 'N/A').toString());
    }).toList();
    showDialog(
        context: context,
        builder: (_) => MemberDetailDialog(title: title, members: members));
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load members: $e')));
    }
  }
}

class _LiveBanner extends StatelessWidget {
  final DashboardStats stats;
  const _LiveBanner({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [AppTheme.primaryOrange, AppTheme.secondaryOrange]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: stats.currentMeal != 'None'
                    ? Colors.greenAccent
                    : Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (stats.currentMeal != 'None'
                            ? Colors.greenAccent
                            : Colors.red)
                        .withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(stats.liveStatus,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
            style:
                TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _SectionHeaderWithAction extends StatelessWidget {
  final String title;
  final VoidCallback onEdit;
  final Widget? trailing;
  const _SectionHeaderWithAction(
      // ignore: unused_element_parameter
      {required this.title,
      required this.onEdit,
      // ignore: unused_element_parameter
      this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      Row(children: [
        if (trailing != null) trailing!,
        TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
            label: const Text('Edit')),
      ]),
    ]);
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final String detail;
  final VoidCallback onRetry;
  const _ErrorView(
      {required this.message, required this.detail, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
            const SizedBox(height: 16),
            Text(message, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(detail,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

Widget _buildMenuSection(
    BuildContext context, String meal, List<String> items) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Icon(meal == 'Lunch' ? Icons.wb_sunny : Icons.nightlight,
            color: AppTheme.primaryOrange, size: 20),
        const SizedBox(width: 8),
        Text(meal, style: Theme.of(context).textTheme.titleMedium),
      ]),
      const SizedBox(height: 8),
      if (items.isEmpty)
        Text('No items',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textSecondary))
      else
        Text(items.join(' • '),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textSecondary)),
    ],
  );
}
