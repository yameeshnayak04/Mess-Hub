import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            onPressed: () => context.go(RouteNames.managerMenu),
            tooltip: 'Edit Menu',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Logout logic
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardStatsProvider.notifier).refresh(),
        child: statsState.when(
          data: (stats) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live Status Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryOrange,
                        AppTheme.secondaryOrange,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
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
                                  color: stats.currentMeal != 'None'
                                      ? Colors.greenAccent.withOpacity(0.5)
                                      : Colors.red.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            stats.liveStatus,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Statistics Cards
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Statistics',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
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
                              context,
                              ref,
                              'Members Eating Now',
                              'eating',
                            ),
                          ),
                          StatCard(
                            title: 'On Leave',
                            value: stats.onLeave.toString(),
                            icon: Icons.beach_access,
                            color: AppTheme.infoBlue,
                            onTap: () => _showMembersDialog(
                              context,
                              ref,
                              'Members On Leave',
                              'leave',
                            ),
                          ),
                          StatCard(
                            title: 'Not Eating (Skipped)',
                            value: stats.notEating.toString(),
                            icon: Icons.cancel_outlined,
                            color: AppTheme.warningYellow,
                            onTap: () => _showMembersDialog(
                              context,
                              ref,
                              'Members Who Skipped',
                              'skipped',
                            ),
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

                      // Today's Menu Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Today's Menu",
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  TextButton.icon(
                                    onPressed: () =>
                                        context.go(RouteNames.managerMenu),
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Edit'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildMenuSection(
                                context,
                                'Lunch',
                                ['Dal Tadka', 'Paneer Curry', 'Roti', 'Rice'],
                              ),
                              const Divider(height: 24),
                              _buildMenuSection(
                                context,
                                'Dinner',
                                ['Chole', 'Aloo Gobi', 'Roti', 'Rice'],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Recent Activity
                      Text(
                        'Recent Activity',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Column(
                          children: [
                            _buildActivityItem(
                              context,
                              icon: Icons.person_add,
                              title: 'New member request',
                              subtitle: 'Rahul Kumar wants to join',
                              time: '5 min ago',
                              color: AppTheme.infoBlue,
                            ),
                            const Divider(height: 1),
                            _buildActivityItem(
                              context,
                              icon: Icons.payment,
                              title: 'Payment received',
                              subtitle: 'Priya Sharma paid ₹2,800',
                              time: '1 hour ago',
                              color: AppTheme.successGreen,
                            ),
                            const Divider(height: 1),
                            _buildActivityItem(
                              context,
                              icon: Icons.beach_access,
                              title: 'Leave application',
                              subtitle: 'Amit Singh applied for 3 days leave',
                              time: '2 hours ago',
                              color: AppTheme.warningYellow,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          loading: () => const LoadingAnimation(
            message: 'Loading dashboard...',
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorRed,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load dashboard',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () =>
                        ref.read(dashboardStatsProvider.notifier).refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    String meal,
    List<String> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              meal == 'Lunch' ? Icons.wb_sunny : Icons.nightlight,
              color: AppTheme.primaryOrange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              meal,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          items.join(' • '),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(
        time,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
      ),
    );
  }

  Future<void> _showMembersDialog(
    BuildContext context,
    WidgetRef ref,
    String title,
    String type,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      List<dynamic> data;
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
        default:
          data = [];
      }

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        final members = data.map((item) {
          final user = item['user'];
          return MemberInfo(
            name: user?['name'] ?? 'Unknown',
            phone: user?['phone'] ?? 'N/A',
          );
        }).toList();

        showDialog(
          context: context,
          builder: (context) => MemberDetailDialog(
            title: title,
            members: members,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load members: $e')),
        );
      }
    }
  }
}
