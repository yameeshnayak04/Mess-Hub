// lib/features/customer/membership/screens/membership_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/membership_providers.dart';
import '../providers/attendance_providers.dart';

class MembershipDashboardScreen extends ConsumerWidget {
  final String membershipId;
  const MembershipDashboardScreen({super.key, required this.membershipId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(membershipDetailsProvider(membershipId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.invalidate(membershipDetailsProvider(membershipId)),
          ),
        ],
      ),
      body: details.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppTheme.primaryOrange),
          ),
        ),
        error: (e, st) => _ErrorRetry(
          message: 'Failed to load dashboard',
          onRetry: () => ref.refresh(membershipDetailsProvider(membershipId)),
        ),
        data: (data) {
          final membership = data['membership'] as Map<String, dynamic>? ?? {};
          final mess = membership['mess'] as Map<String, dynamic>? ?? {};
          final messId = (mess['_id'] as String?) ?? '';
          final menu = data['todaysMenu'] as Map<String, dynamic>?;
          final summary =
              data['attendanceSummary'] as Map<String, dynamic>? ?? {};

          return RefreshIndicator(
            color: AppTheme.primaryOrange,
            onRefresh: () async {
              ref.invalidate(membershipDetailsProvider(membershipId));
              await ref.read(membershipDetailsProvider(membershipId).future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mess Info Card
                  _MessInfoCard(messName: mess['messName'] ?? 'N/A'),

                  const SizedBox(height: 16),

                  // Today's Menu
                  _MenuCard(menu: menu),

                  const SizedBox(height: 16),

                  // Summary chips
                  _SummaryRow(summary: summary),

                  const SizedBox(height: 16),

                  // Skip meal actions
                  _SkipMealCard(
                    membershipId: membershipId,
                    onSkip: (meal) => _skip(context, ref, meal),
                  ),

                  const SizedBox(height: 16),

                  // Actions grid
                  _ActionsGrid(
                    membershipId: membershipId,
                    messId: messId,
                    onLeaveMembership: () => _confirmLeave(context, ref),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _skip(BuildContext context, WidgetRef ref, String meal) async {
    try {
      await ref.read(attendanceRepositoryProvider).skipMeal(
            membershipId: membershipId,
            mealType: meal,
            date: DateTime.now(), // explicit for reliability
          );
      ref.invalidate(membershipDetailsProvider(membershipId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$meal skipped successfully'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.invalidate(membershipDetailsProvider(membershipId));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to skip $meal: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmLeave(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Membership'),
        content: const Text(
          'Are you sure you want to leave this mess? Outstanding dues may block deactivation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(membershipRepositoryProvider)
                    .leaveMess(membershipId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Leave request submitted'),
                      backgroundColor: AppTheme.successGreen,
                    ),
                  );
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed: ${e.toString()}'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

// Mess Info Card
class _MessInfoCard extends StatelessWidget {
  final String messName;
  const _MessInfoCard({required this.messName});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lightOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.restaurant,
                color: AppTheme.primaryOrange,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    messName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Active Membership',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.successGreen,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Menu Card
class _MenuCard extends StatelessWidget {
  final Map<String, dynamic>? menu;
  const _MenuCard({required this.menu});

  @override
  Widget build(BuildContext context) {
    final lunchItems = (menu?['lunchItems'] as List?)?.cast<String>() ?? [];
    final dinnerItems = (menu?['dinnerItems'] as List?)?.cast<String>() ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant_menu,
                    color: AppTheme.primaryOrange),
                const SizedBox(width: 8),
                Text("Today's Menu",
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            _buildMenuSection(context, 'Lunch', lunchItems),
            if (lunchItems.isNotEmpty && dinnerItems.isNotEmpty)
              const Divider(height: 24),
            _buildMenuSection(context, 'Dinner', dinnerItems),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(
      BuildContext context, String meal, List<String> items) {
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                meal == 'Lunch' ? Icons.wb_sunny : Icons.nightlight,
                color: AppTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(meal, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'No menu available',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      );
    }

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
            Text(meal, style: Theme.of(context).textTheme.titleMedium),
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
                      fontWeight: FontWeight.w500,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// Summary Row
class _SummaryRow extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _SummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This Month', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(context, 'Present', summary['present'] ?? 0,
                    AppTheme.successGreen),
                _buildStat(context, 'Skipped', summary['skipped'] ?? 0,
                    AppTheme.warningYellow),
                _buildStat(
                    context, 'Leave', summary['leave'] ?? 0, AppTheme.infoBlue),
                _buildStat(context, 'Absent', summary['absent'] ?? 0,
                    AppTheme.errorRed),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
      BuildContext context, String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
      ],
    );
  }
}

// Skip Meal Card
class _SkipMealCard extends StatelessWidget {
  final String membershipId;
  final Function(String) onSkip;
  const _SkipMealCard({required this.membershipId, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Toggle Meal Skip',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
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
                    onPressed: () => onSkip('Lunch'),
                    icon: const Icon(Icons.wb_sunny_outlined),
                    label: const Text('Skip Lunch'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onSkip('Dinner'),
                    icon: const Icon(Icons.nightlight_outlined),
                    label: const Text('Skip Dinner'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Actions Grid
class _ActionsGrid extends StatelessWidget {
  final String membershipId;
  final String messId;
  final VoidCallback onLeaveMembership;
  const _ActionsGrid(
      {required this.membershipId,
      required this.messId,
      required this.onLeaveMembership});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _ActionCard(
          icon: Icons.calendar_today,
          title: 'View Attendance',
          color: AppTheme.infoBlue,
          onTap: () => context.push('/attendance-calendar/$membershipId'),
        ),
        _ActionCard(
          icon: Icons.beach_access,
          title: 'Apply for Leave',
          color: AppTheme.warningYellow,
          onTap: () => context.push('/apply-leave/$membershipId'),
        ),
        _ActionCard(
          icon: Icons.receipt_long,
          title: 'View & Pay Bills',
          color: AppTheme.successGreen,
          onTap: () => context.push('/billing/$membershipId'),
        ),
        _ActionCard(
          icon: Icons.rate_review,
          title: 'Add/Edit Review',
          color: AppTheme.primaryOrange,
          onTap: () async {
            final changed = await context.push<Map?>('/review-editor/$messId');
            if (changed == true && context.mounted) {
              // If you later show average rating somewhere, refresh providers here.
              // ref.invalidate(membershipDetailsProvider(membershipId)); // if using in a ConsumerWidget scope
            }
          },
        ),
        _ActionCard(
          icon: Icons.exit_to_app,
          title: 'Leave Membership',
          color: AppTheme.errorRed,
          onTap: onLeaveMembership,
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                child: Icon(icon, color: color, size: 32),
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
}

// Error Retry Widget
class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
