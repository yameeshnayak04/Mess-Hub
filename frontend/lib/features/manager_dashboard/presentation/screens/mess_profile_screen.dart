// lib/features/manager_dashboard/presentation/screens/mess_profile_screen.dart (FIXED)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/providers/manager_dashboard_provider.dart';

class MessProfileScreen extends ConsumerWidget {
  const MessProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(managerDashboardProvider);
    final profile = dashboardState.messProfile;

    return Scaffold(
      appBar: AppBar(title: const Text('Mess Profile')),
      body: dashboardState.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...'),
                ],
              ),
            )
          : profile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Failed to load mess profile'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(managerDashboardProvider.notifier)
                            .loadDashboard(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      size: 18, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${profile.address}, ${profile.city}',
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                children: [
                                  Chip(
                                    avatar:
                                        const Icon(Icons.restaurant, size: 16),
                                    label: Text(profile.cuisine),
                                  ),
                                  Chip(
                                    avatar: const Icon(Icons.card_membership,
                                        size: 16),
                                    label: Text(profile.serviceType),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              color: Colors.blue.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Text(
                                      '${profile.totalMembers}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade700,
                                          ),
                                    ),
                                    const Text('Total Members'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Card(
                              color: Colors.amber.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.star,
                                            color: Colors.amber.shade700,
                                            size: 28),
                                        const SizedBox(width: 4),
                                        Text(
                                          profile.averageRating
                                              .toStringAsFixed(1),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber.shade700,
                                              ),
                                        ),
                                      ],
                                    ),
                                    Text('${profile.totalRatings} Ratings'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Pricing Section
                      Text(
                        'Pricing',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (profile.dailyThaliRate != null)
                        ListTile(
                          leading:
                              const CircleAvatar(child: Icon(Icons.fastfood)),
                          title: const Text('Daily Thali Rate'),
                          trailing: Text(
                            '₹${profile.dailyThaliRate!.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      const Divider(),
                      ...profile.mealPlans.map((plan) {
                        return ListTile(
                          leading: CircleAvatar(child: Text(plan.name[0])),
                          title: Text(plan.name),
                          subtitle: Text(
                              'Rebate: ₹${plan.perThaliRebateRate.toStringAsFixed(0)}/thali'),
                          trailing: Text(
                            '₹${plan.price.toStringAsFixed(0)}/month',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
    );
  }
}
