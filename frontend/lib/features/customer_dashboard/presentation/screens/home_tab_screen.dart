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
          onRefresh: () => notifier.loadMemberships(),
          child: state.isLoading && state.memberships.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : state.memberships.isEmpty
                  ? _buildEmptyState(context)
                  : CustomScrollView(
                      slivers: [
                        _buildAppBar(context, state),
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              // Active Membership Card
                              if (state.selectedMembership != null)
                                MembershipCard(
                                  membership: state.selectedMembership!,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/membership-detail',
                                      arguments: state.selectedMembership!,
                                    );
                                  },
                                ),
                              const SizedBox(height: 20),

                              // Today's Menu Card
                              if (state.selectedMembership?.isActive ?? false)
                                TodayMenuCard(
                                  menu: state.todayMenu,
                                  membership: state.selectedMembership!,
                                ),
                              const SizedBox(height: 20),

                              // Meal Skip Toggle
                              if (state.selectedMembership?.isActive ?? false)
                                MealSkipToggle(
                                  membership: state.selectedMembership!,
                                  mealTimings: state.mealTimings,
                                  onToggle: (mealType) {
                                    notifier.toggleMealSkip(mealType);
                                  },
                                ),
                              const SizedBox(height: 20),

                              // Quick Actions Grid
                              if (state.selectedMembership?.isActive ?? false)
                                QuickActionsGrid(
                                  membership: state.selectedMembership!,
                                ),
                              const SizedBox(height: 20),

                              // Other Memberships
                              if (state.memberships.length > 1)
                                _buildOtherMemberships(
                                    context, state, notifier),
                            ]),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, CustomerDashboardState state) {
    final now = DateTime.now();
    final greeting = _getGreeting();

    return SliverAppBar(
      floating: true,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      expandedHeight: 120,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                greeting,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, MMMM d, y').format(now),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'No Active Memberships',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Discover and join nearby messes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to Discover tab
            },
            icon: const Icon(Icons.explore),
            label: const Text('Discover Messes'),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherMemberships(
    BuildContext context,
    CustomerDashboardState state,
    CustomerDashboardNotifier notifier,
  ) {
    final otherMemberships = state.memberships
        .where((m) => m.id != state.selectedMembership?.id)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Other Memberships',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...otherMemberships.map((membership) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MembershipCard(
                membership: membership,
                isCompact: true,
                onTap: () {
                  notifier.selectMembership(membership);
                },
              ),
            )),
      ],
    );
  }
}
