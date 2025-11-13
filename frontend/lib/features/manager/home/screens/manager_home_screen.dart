// lib/features/manager/dashboard/screens/manager_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_animation.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/widgets/member_detail_dialog.dart';
import '../../../../core/utils/constants.dart';
import '../providers/dashboard_provider.dart';
import '../../../../models/dashboard_stats.dart';

class ManagerHomeScreen extends ConsumerWidget {
  const ManagerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsState = ref.watch(dashboardStatsProvider);
    final approvals = ref.watch(pendingApprovalsProvider);
    final joinRequests = ref.watch(pendingJoinRequestsProvider);
    final todaysMenu = ref.watch(todaysMenuProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        color: AppTheme.primaryOrange,
        onRefresh: () async {
          await ref.read(dashboardStatsProvider.notifier).refresh();
          ref.invalidate(pendingApprovalsProvider);
          ref.invalidate(pendingJoinRequestsProvider);
          ref.invalidate(todaysMenuProvider);
        },
        child: statsState.when(
          loading: () =>
              const LoadingAnimation(message: 'Loading dashboard...'),
          error: (e, _) => _ErrorView(
            message: 'Failed to load dashboard',
            detail: e.toString(),
            onRetry: () => ref.read(dashboardStatsProvider.notifier).refresh(),
          ),
          data: (stats) {
            final meal = stats.currentMeal;
            final mealTag = meal == 'None' ? '' : ' • $meal';
            final eaten = stats.eaten;
            final onLeave = stats.onLeave;
            final skipped = stats.skipped;
            final eligible = stats.totalActiveMembers;
            final remaining =
                (eligible - eaten - onLeave - skipped).clamp(0, 1 << 30);

            return SingleChildScrollView(
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
                            // 1. Members remaining (popup)
                            StatCard(
                              title: 'Members remaining$mealTag',
                              value: remaining.toString(),
                              icon: Icons.groups_2_rounded,
                              color: AppTheme.infoBlue,
                              onTap: () => _showMembersDialog(context, ref,
                                  'Members remaining', 'remaining'),
                            ),
                            // 2. Members eaten (popup)
                            StatCard(
                              title: 'Members eaten$mealTag',
                              value: eaten.toString(),
                              icon: Icons.restaurant_rounded,
                              color: Colors.teal,
                              onTap: () => _showMembersDialog(
                                  context, ref, 'Members eaten', 'eating'),
                            ),
                            // 3. On leave (popup)
                            StatCard(
                              title: 'On leave$mealTag',
                              value: onLeave.toString(),
                              icon: Icons.beach_access_rounded,
                              color: AppTheme.warningYellow,
                              onTap: () => _showMembersDialog(
                                  context, ref, 'On leave', 'leave'),
                            ),
                            // 4. Skipped (popup)
                            StatCard(
                              title: 'Skipped$mealTag',
                              value: skipped.toString(),
                              icon: Icons.remove_circle_outline,
                              color: Colors.pinkAccent,
                              onTap: () => _showMembersDialog(
                                  context, ref, 'Skipped', 'skipped'),
                            ),
                            // 5. Daily Members (no popup)
                            StatCard(
                              title: 'Daily Members$mealTag',
                              value: (stats.dailyMembers ?? 0).toString(),
                              icon: Icons.calendar_month_rounded,
                              color: AppTheme.primaryOrange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Today’s Menu
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
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
                          error: (e, _) => Row(
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
                                          .pushNamed(RouteNames.managerMenu),
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
                  ),

                  const SizedBox(height: 24),

                  // Action Center: Approvals
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ActionCenter(
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
                                  backgroundColor: Colors.teal),
                            );
                          }
                          ref.invalidate(pendingApprovalsProvider);
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
                          }
                          ref.invalidate(pendingApprovalsProvider);
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
                                  backgroundColor: Colors.teal),
                            );
                          }
                          ref.invalidate(pendingJoinRequestsProvider);
                          await ref
                              .read(dashboardStatsProvider.notifier)
                              .refresh();
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
                          }
                          ref.invalidate(pendingJoinRequestsProvider);
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
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- THIS IS THE FIXED FUNCTION ---
  Future<void> _showMembersDialog(
    BuildContext context,
    WidgetRef ref,
    String title,
    String type,
  ) async {
    // Show loader on ROOT navigator so it’s independent of nested GoRouter stacks
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final rootNav = Navigator.of(context, rootNavigator: true);
    List<Map<String, dynamic>> data;

    try {
      // 1. Fetch data based on type
      switch (type) {
        case 'eating':
          data = await ref
              .read(dashboardStatsProvider.notifier)
              .getMembersEating();
          break;
        case 'leave':
          data = await ref
              .read(dashboardStatsProvider.notifier)
              .getMembersOnLeave();
          break;
        case 'skipped':
          data = await ref
              .read(dashboardStatsProvider.notifier)
              .getMembersSkipped();
          break;
        case 'remaining':
          data = await ref
              .read(dashboardStatsProvider.notifier)
              .getMembersRemaining();
          break;
        default:
          data = const <Map<String, dynamic>>[];
      }

      if (!context.mounted) return;

      // 2. Close loader
      if (rootNav.canPop()) rootNav.pop();

      // 3. Parse data into MemberInfo list
      // This logic is preserved from your original file
      final members = data.map<MemberInfo>((item) {
        final user = (item['user'] is Map)
            ? Map<String, dynamic>.from(item['user'] as Map)
            : <String, dynamic>{};
        final name = (item['name'] ?? user['name'] ?? 'Unknown').toString();

        // Normalize phone: empty -> null
        final phoneRaw =
            (item['phone'] ?? user['phone'])?.toString().trim() ?? '';
        return MemberInfo(name: name, phone: phoneRaw); // phone is String
      }).toList();

      // 4. Show the appropriate dialog (MemberDetailDialog or "No members")
      showDialog(
        context: context,
        useRootNavigator: true,
        builder: (_) {
          if (members.isEmpty) {
            return AlertDialog(
              title: Text(title),
              content: const Text('No members found'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(_, rootNavigator: true).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          }
          return MemberDetailDialog(title: title, members: members);
        },
      );
    } catch (e) {
      // Handle any errors during fetch
      if (!context.mounted) return;
      if (rootNav.canPop()) rootNav.pop(); // Close loader

      showDialog(
        context: context,
        useRootNavigator: true,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to load member list: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(_, rootNavigator: true).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}
// --- END OF FIXED FUNCTION ---

class _LiveBanner extends StatelessWidget {
  final DashboardStats stats;
  const _LiveBanner({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isOngoing = stats.currentMeal != 'None';
    final statusText = isOngoing
        ? '${stats.currentMeal} Ongoing' // Simpler text
        : 'Closed'; // Use liveStatus for next
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
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
                color: isOngoing ? Colors.greenAccent : Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isOngoing ? Colors.greenAccent : Colors.red)
                        .withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(statusText,
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

class _ActionCenter extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> approvals;
  final AsyncValue<List<Map<String, dynamic>>> joinRequests;
  final ValueChanged<String> onApprovePayment;
  final ValueChanged<String> onRejectPayment;
  final ValueChanged<String> onApproveMember;
  final ValueChanged<String> onRejectMember;

  const _ActionCenter({
    required this.approvals,
    required this.joinRequests,
    required this.onApprovePayment,
    required this.onRejectPayment,
    required this.onApproveMember,
    required this.onRejectMember,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment approvals',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        approvals.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Failed to load payments: $e'),
          data: (bills) {
            if (bills.isEmpty) {
              return Text('No pending approvals',
                  style: Theme.of(context).textTheme.bodySmall);
            }
            return Column(
              children: bills.map((b) {
                final billId = (b['_id'] ?? '').toString();
                final memberName =
                    (b['member']?['name'] ?? b['user']?['name'] ?? 'Member')
                        .toString();
                final amount = (b['amount'] ?? 0).toString();
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text(memberName),
                    subtitle: Text('Amount: $amount'),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          tooltip: 'Reject',
                          icon:
                              const Icon(Icons.close, color: AppTheme.errorRed),
                          onPressed: () => onRejectPayment(billId),
                        ),
                        IconButton(
                          tooltip: 'Approve',
                          icon: const Icon(Icons.check_circle,
                              color: Colors.teal),
                          onPressed: () => onApprovePayment(billId),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 16),
        Text('Join requests', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        joinRequests.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Failed to load join requests: $e'),
          data: (joins) {
            if (joins.isEmpty) {
              return Text('No join requests',
                  style: Theme.of(context).textTheme.bodySmall);
            }
            return Column(
              children: joins.map((m) {
                final membershipId = (m['_id'] ?? '').toString();
                final uName = (m['user']?['name'] ?? 'Member').toString();
                final planName = (m['planName'] ?? '-').toString();
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_add_alt_1),
                    title: Text(uName),
                    subtitle: Text('Plan: $planName'),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          tooltip: 'Reject',
                          icon:
                              const Icon(Icons.close, color: AppTheme.errorRed),
                          onPressed: () => onRejectMember(membershipId),
                        ),
                        IconButton(
                          tooltip: 'Approve',
                          icon: const Icon(Icons.check_circle,
                              color: Colors.teal),
                          onPressed: () => onApproveMember(membershipId),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
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
