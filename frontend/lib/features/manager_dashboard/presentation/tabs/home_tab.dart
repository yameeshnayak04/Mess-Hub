// lib/features/manager_dashboard/presentation/tabs/home_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/weekly_menu.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/providers/manager_dashboard_provider.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/widgets/stats_card.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});
  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  Future<void> _fetchData() async {
    await ref.read(managerDashboardProvider.notifier).fetchHomeData();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(managerDashboardProvider);
    final textTheme = Theme.of(context).textTheme;
    return RefreshIndicator(
        onRefresh: _fetchData, child: _buildBody(state, textTheme));
  }

  Widget _buildBody(ManagerDashboardState state, TextTheme textTheme) {
    if (state.isLoading && state.stats == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(child: Text('An error occurred: ${state.error}'));
    }
    if (state.stats == null) {
      return const Center(child: Text('No data. Pull to refresh.'));
    }

    final stats = state.stats!;
    final today = DateFormat('EEEE').format(DateTime.now());
    final WeeklyMenu? week = state.weeklyMenu;
    DayMenu? todayMenu;
    if (week != null) {
      try {
        todayMenu = week.days.firstWhere((d) => d.day == today);
      } catch (_) {
        todayMenu = null;
      }
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "Today's Menu (${DateFormat('dd MMM').format(DateTime.now())})",
                        style: textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text("Lunch: ${todayMenu?.lunch ?? 'Not set'}",
                        style: textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    Text("Dinner: ${todayMenu?.dinner ?? 'Not set'}",
                        style: textTheme.bodyLarge),
                    Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                            onPressed: () {}, child: const Text("Edit Menu"))),
                  ]),
            ),
          ),
          const SizedBox(height: 24),
          Text('Live Meal Status',
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              StatsCard(
                  title: 'Eaten',
                  value: '${stats.monthlyMembersEaten} / ${stats.totalMembers}',
                  icon: Icons.restaurant_menu_rounded),
              StatsCard(
                  title: 'Remaining',
                  value: '${stats.membersRemaining}',
                  icon: Icons.people_alt_outlined),
              StatsCard(
                  title: 'On Leave Today',
                  value: '${stats.membersOnLeave}',
                  icon: Icons.flight_takeoff_rounded),
              StatsCard(
                  title: 'Daily Users Today',
                  value: '${stats.dailyUsersEaten}',
                  icon: Icons.person_add_alt_1_rounded),
            ],
          ),
        ],
      ),
    );
  }
}
