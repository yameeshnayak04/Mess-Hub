// lib/features/manager_dashboard/presentation/widgets/home_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/providers/manager_dashboard_provider.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/widgets/stats_card.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/widgets/menu_upload_dialog.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(managerDashboardProvider);

    if (dashboardState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dashboardState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(dashboardState.error!),
            ElevatedButton(
              onPressed: () =>
                  ref.read(managerDashboardProvider.notifier).loadDashboard(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final stats = dashboardState.stats;
    if (stats == null) {
      return const Center(child: Text('No stats available'));
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(managerDashboardProvider.notifier).loadDashboard(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload Menu Button
            Card(
              color: Colors.deepOrange.shade50,
              child: InkWell(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const MenuUploadDialog(),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.restaurant_menu,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upload Today\'s Menu',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Let your members know what\'s cooking!',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Stats Grid
            Text(
              'Today\'s Overview',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                StatsCard(
                  title: 'Total Members',
                  value: '${stats.totalMembers}',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                StatsCard(
                  title: 'On Leave',
                  value: '${stats.membersOnLeave}',
                  icon: Icons.event_busy,
                  color: Colors.orange,
                ),
                StatsCard(
                  title: 'Lunch To Prepare',
                  value: '${stats.mealsToPrepareLunch}',
                  icon: Icons.wb_sunny,
                  color: Colors.amber,
                ),
                StatsCard(
                  title: 'Dinner To Prepare',
                  value: '${stats.mealsToPrepareDinner}',
                  icon: Icons.nights_stay,
                  color: Colors.indigo,
                ),
                StatsCard(
                  title: 'Meals Eaten',
                  value: '${stats.totalMealsEaten}',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                StatsCard(
                  title: 'Daily Walk-ins',
                  value: '${stats.dailyUsersEaten}',
                  icon: Icons.directions_walk,
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
