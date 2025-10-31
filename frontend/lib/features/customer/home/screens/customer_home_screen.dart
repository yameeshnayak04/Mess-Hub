// lib/features/customer/home/screens/customer_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_animation.dart';
import '../../../auth/providers/auth_provider.dart';
import '../providers/membership_provider.dart';
import '../../../../models/membership.dart';
import '../../../../models/mess.dart'; // Import Mess model

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final membershipsState =
        ref.watch(membershipProvider); // Watch the StateNotifierProvider

    // Get user's first name, default to 'Customer'
    final String userName = authState.maybeWhen(
      data: (u) => u?.name.split(' ').first ?? 'Customer',
      orElse: () => 'Customer',
    );

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140),
        child: Container(
          // Match screenshot color
          decoration: const BoxDecoration(
            color: Color(0xFF1976D2), // Solid blue from screenshot
          ),
          padding: EdgeInsets.fromLTRB(
              16, MediaQuery.of(context).padding.top + 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${_greeting()}, $userName',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24, // Match screenshot
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              // Match screenshot format (e.g., Friday, October 31)
              Text(DateFormat('EEEE, MMMM dd').format(DateTime.now()),
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14)), // Match screenshot
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(membershipProvider.notifier).refresh(),
        child: membershipsState.when(
          loading: () =>
              const LoadingAnimation(message: 'Loading memberships...'),
          error: (e, stack) => Center(
            // Show error message nicely
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppTheme.errorRed, size: 50),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load memberships',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString(), // Display the actual error
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          data: (memberships) {
            final activeCount =
                memberships.where((m) => m.status == 'Active').length;

            // Use ListView.custom for empty state + list
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  16, 20, 16, 24), // Match screenshot padding
              // Add 1 for the header row + 1 for the hint card
              itemCount: memberships.length + 2,
              separatorBuilder: (context, index) {
                // No separator after header
                if (index == 0) return const SizedBox(height: 16);
                // No separator before hint card
                if (index == memberships.length)
                  return const SizedBox(height: 12);
                // Separator between membership cards (which is just margin)
                return const SizedBox(height: 0); // Cards have their own margin
              },
              itemBuilder: (context, index) {
                // --- HEADER ---
                if (index == 0) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Memberships',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$activeCount Active',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // --- HINT CARD (at the end) ---
                if (index == memberships.length + 1) {
                  return _hintCard();
                }

                // --- EMPTY STATE (if list is empty) ---
                if (memberships.isEmpty) {
                  // This is shown at index 1 if count is 0
                  return _buildEmptyState(context);
                }

                // --- MEMBERSHIP CARD ---
                // Adjust index to get from list
                final membership = memberships[index - 1];
                return _membershipCard(context, membership);
              },
            );
          },
        ),
      ),
    );
  }

  // Card for when no memberships are found
  Widget _buildEmptyState(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.restaurant_outlined,
              size: 80,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Memberships Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Discover and join messes near you to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/discover'),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Discover Messes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // This is the card widget matching the screenshot
  Widget _membershipCard(BuildContext context, Membership m) {
    final mess = m.messObject; // This is an enriched Mess object
    final joined = m.joinedDate != null
        ? DateFormat('MMM d, y').format(m.joinedDate!)
        : '-';
    final bool isActive = m.status == 'Active';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1, // Subtle shadow
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        // Navigate to dashboard only if active
        onTap:
            isActive ? () => context.go('/membership-dashboard/${m.id}') : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16), // Match padding
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue[50], // Match screenshot
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(12), // Match screenshot
                child: const Icon(Icons.flatware,
                    color: Colors.blue, size: 28), // Match screenshot
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mess Name & Rating
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            mess?.messName ?? 'Mess',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                    fontWeight:
                                        FontWeight.w600), // Match screenshot
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // *** FIX: Add null check for mess object as well ***
                        if (mess?.averageRating != null &&
                            mess!.averageRating! > 0) ...[
                          const Icon(Icons.star,
                              size: 18,
                              color: Color(0xFFFFC107)), // Match screenshot
                          const SizedBox(width: 4),
                          Text(
                            mess.averageRating!.toStringAsFixed(1),
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ), // Match screenshot
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Plan & Status Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _planChip(m.planName),
                        _statusChip(m.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Price
                    Text('₹${m.billingRate.toStringAsFixed(0)}/month',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge // Match screenshot
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    // Member Since
                    Text('Member since: $joined',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary)), // Match screenshot
                  ],
                ),
              ),
              // Chevron
              if (isActive)
                const Icon(Icons.chevron_right, color: Colors.black45)
              else
                // Maintain space even if inactive
                const SizedBox(width: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Status Chip (Active, Pending)
  Widget _statusChip(String status) {
    Color bg = AppTheme.borderColor;
    Color fg = AppTheme.textSecondary;
    if (status == 'Active') {
      bg = AppTheme.successGreen.withOpacity(0.1); // Match screenshot
      fg = AppTheme.successGreen;
    } else if (status == 'Pending') {
      bg = AppTheme.warningYellow.withOpacity(0.1); // Match screenshot
      fg = AppTheme.warningYellow;
    } else if (status == 'Inactive') {
      bg = Colors.grey.shade200;
      fg = Colors.grey.shade700;
    }
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Smaller
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)), // Rounded
      child: Text(status,
          style:
              TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  // Plan Chip (Lunch Only, Dinner Only)
  Widget _planChip(String plan) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Smaller
      decoration: BoxDecoration(
        color: Colors.blue[50], // Match screenshot
        borderRadius: BorderRadius.circular(6), // Rounded
      ),
      child: Text(plan,
          style: const TextStyle(
              color: Colors.blue, // Match screenshot
              fontWeight: FontWeight.w600,
              fontSize: 12)),
    );
  }

  // Hint Card at the bottom
  Widget _hintCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50], // Match screenshot
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates,
              color: Colors.blue[700], size: 20), // Match screenshot
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tap on any membership to view attendance, bills, apply for leave, and more.',
              style: TextStyle(
                  color: Colors.blue[900], fontSize: 13), // Match screenshot
            ),
          ),
        ],
      ),
    );
  }
}
