// This screen is the main dashboard for a logged-in mess manager.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/providers/manager_dashboard_provider.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/widgets/stats_card.dart';

class ManagerDashboardScreen extends ConsumerStatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  ConsumerState<ManagerDashboardScreen> createState() =>
      _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState
    extends ConsumerState<ManagerDashboardScreen> {
  // Fetch the data when the screen is first loaded.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(managerDashboardProvider.notifier).fetchDashboardStats();
    });
  }

  // Helper function for pull-to-refresh.
  Future<void> _refreshStats() async {
    await ref.read(managerDashboardProvider.notifier).fetchDashboardStats();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider to get the current state and rebuild when it changes.
    final state = ref.watch(managerDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        actions: [
          // A logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // TODO: Implement logout functionality
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshStats,
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(ManagerDashboardState state) {
    if (state.isLoading && state.stats == null) {
      return const Center(child: CircularProgressIndicator());
    } else if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'An error occurred: ${state.error}\n\nPull down to try again.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (state.stats == null) {
      return const Center(
          child: Text('No data available. Pull down to refresh.'));
    }

    // If we have data, display the dashboard.
    final stats = state.stats!;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Live Meal Status',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // A grid to display the key statistics.
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              StatsCard(
                title: 'Meals to Prepare',
                value: stats.mealsToPrepare.toString(),
                icon: Icons.kitchen,
                iconColor: Colors.blue,
              ),
              StatsCard(
                title: 'Total Meals Eaten',
                value: stats.totalMealsEaten.toString(),
                icon: Icons.restaurant,
                iconColor: Colors.green,
              ),
              StatsCard(
                title: 'Members Remaining',
                value: stats.membersRemaining.toString(),
                icon: Icons.people_alt_outlined,
                iconColor: Colors.orange,
              ),
              StatsCard(
                title: 'Daily Users Today',
                value: stats.dailyUsersEaten.toString(),
                icon: Icons.person,
                iconColor: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Buttons for other management actions
          ElevatedButton.icon(
            onPressed: () {/* TODO: Navigate to Member List Screen */},
            icon: const Icon(Icons.group),
            label: const Text('View All Members'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {/* TODO: Navigate to Rules Screen */},
            icon: const Icon(Icons.rule),
            label: const Text('Configure Mess Rules'),
          )
        ],
      ),
    );
  }
}
