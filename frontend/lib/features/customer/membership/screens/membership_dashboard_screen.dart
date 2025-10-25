import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_animation.dart';
import '../../../../models/membership.dart';

class MembershipDashboardScreen extends ConsumerWidget {
  final String membershipId;

  const MembershipDashboardScreen({
    super.key,
    required this.membershipId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now, showing a placeholder
    // You would implement providers to fetch membership details, menu, etc.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's Menu Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Menu",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildMenuSection(context, 'Lunch', [
                      'Dal Tadka',
                      'Paneer Butter Masala',
                      'Roti',
                      'Rice',
                      'Salad'
                    ]),
                    const Divider(height: 24),
                    _buildMenuSection(context, 'Dinner',
                        ['Chole', 'Aloo Gobi', 'Roti', 'Rice', 'Raita']),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Skip Meal Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toggle Meal Skip',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Skip meals before the meal time ends to get rebate',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Skip lunch logic
                            },
                            icon: const Icon(Icons.wb_sunny_outlined),
                            label: const Text('Skip Lunch'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Skip dinner logic
                            },
                            icon: const Icon(Icons.nightlight_outlined),
                            label: const Text('Skip Dinner'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildActionCard(
                  context,
                  icon: Icons.calendar_today,
                  title: 'View Attendance',
                  color: AppTheme.infoBlue,
                  onTap: () => context.go('/attendance-calendar/$membershipId'),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.beach_access,
                  title: 'Apply for Leave',
                  color: AppTheme.warningYellow,
                  onTap: () => context.go('/apply-leave/$membershipId'),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.receipt_long,
                  title: 'View & Pay Bills',
                  color: AppTheme.successGreen,
                  onTap: () => context.go('/billing/$membershipId'),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.exit_to_app,
                  title: 'Leave Membership',
                  color: AppTheme.errorRed,
                  onTap: () => _showLeaveMembershipDialog(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(
      BuildContext context, String meal, List<String> items) {
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map((item) => Chip(
                    label: Text(item),
                    backgroundColor: AppTheme.lightOrange,
                    labelStyle: const TextStyle(
                      color: AppTheme.primaryOrange,
                      fontSize: 12,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLeaveMembershipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Membership'),
        content: const Text(
          'Are you sure you want to leave this mess? You must clear all outstanding dues first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement leave logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please clear your outstanding dues first'),
                  backgroundColor: AppTheme.errorRed,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}
