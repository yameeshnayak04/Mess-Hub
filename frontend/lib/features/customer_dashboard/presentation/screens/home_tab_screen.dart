// lib/features/customer_dashboard/presentation/screens/home_tab_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/providers/customer_dashboard_provider.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/widgets/membership_card.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/widgets/today_menu_card.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/widgets/meal_skip_toggle.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/widgets/quick_actions_grid.dart';

class HomeTabScreen extends ConsumerWidget {
  const HomeTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerDashboardProvider);
    final notifier = ref.read(customerDashboardProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await notifier.loadMemberships();
          },
          child: state.memberships.isEmpty
              ? _buildEmpty(context)
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      floating: true,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      expandedHeight: 120,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _greeting(),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('EEEE, MMMM d')
                                    .format(DateTime.now()),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withOpacity(0.7),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          if (state.selectedMembership != null)
                            MembershipCard(
                                membership: state.selectedMembership!),
                          const SizedBox(height: 16),
                          if (state.selectedMembership?.isActive ?? false)
                            TodayMenuCard(
                                menu: state.todayMenu,
                                membership: state.selectedMembership!),
                          const SizedBox(height: 16),
                          if (state.selectedMembership?.isActive ?? false)
                            MealSkipToggle(
                              membership: state.selectedMembership!,
                              mealTimings: state.mealTimings,
                              onToggle: (meal) => notifier.toggleMealSkip(meal),
                            ),
                          const SizedBox(height: 16),
                          if (state.selectedMembership?.isActive ?? false)
                            QuickActionsGrid(
                                membership: state.selectedMembership!),
                        ]),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu, size: 96, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No memberships yet',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Discover and join nearby messes.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
