// lib/features/manager/dashboard/screens/manager_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_animation.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/widgets/member_detail_dialog.dart';
import '../../../../core/utils/constants.dart';
import '../providers/dashboard_provider.dart';
import '../../../../models/dashboard_stats.dart';

class ManagerHomeScreen extends ConsumerWidget {
  const ManagerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsState = ref.watch(dashboardStatsProvider);
    final approvals = ref.watch(pendingApprovalsProvider);
    final joinRequests = ref.watch(pendingJoinRequestsProvider);
    final todaysMenu = ref.watch(todaysMenuProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        color: AppTheme.primaryOrange,
        onRefresh: () async {
          await ref.read(dashboardStatsProvider.notifier).refresh();
          ref.invalidate(pendingApprovalsProvider);
          ref.invalidate(pendingJoinRequestsProvider);
          ref.invalidate(todaysMenuProvider);
        },
        child: statsState.when(
          loading: () =>
              const LoadingAnimation(message: 'Loading dashboard...'),
          error: (e, _) => _ErrorView(
            message: 'Failed to load dashboard',
            detail: e.toString(),
            onRetry: () => ref.read(dashboardStatsProvider.notifier).refresh(),
          ),
          data: (stats) {
            final meal = stats.currentMeal;
            final mealTag = meal == 'None' ? '' : ' • $meal';
            final eaten = stats.eaten;
            final onLeave = stats.onLeave;
            final skipped = stats.skipped;
            final eligible = stats.totalActiveMembers;
            final remaining =
                (eligible - eaten - onLeave - skipped).clamp(0, 1 << 30);

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Modern App Bar with Live Status
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: AppTheme.primaryOrange,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _ModernLiveBanner(stats: stats),
                  ),
                  title: const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined,
                          color: Colors.white),
                      onPressed: () {
                        // TODO: Navigate to notifications
                      },
                    ),
                  ],
                ),

                // Main Content
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      // Live Statistics Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryOrange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.analytics_outlined,
                                color: AppTheme.primaryOrange,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Live Statistics',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Modern Stat Cards Grid
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // Row 1: Remaining & Eaten
                            Row(
                              children: [
                                Expanded(
                                  child: _ModernStatCard(
                                    title: 'Remaining',
                                    subtitle: mealTag.isNotEmpty
                                        ? mealTag.substring(3)
                                        : '',
                                    value: remaining.toString(),
                                    icon: Icons.groups_2_rounded,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF667EEA),
                                        Color(0xFF764BA2)
                                      ],
                                    ),
                                    onTap: () => _showMembersDialog(
                                      context,
                                      ref,
                                      'Members remaining',
                                      'remaining',
                                      stats.currentMeal,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ModernStatCard(
                                    title: 'Eaten',
                                    subtitle: mealTag.isNotEmpty
                                        ? mealTag.substring(3)
                                        : '',
                                    value: eaten.toString(),
                                    icon: Icons.restaurant_rounded,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF11998E),
                                        Color(0xFF38EF7D)
                                      ],
                                    ),
                                    onTap: () => _showMembersDialog(
                                      context,
                                      ref,
                                      'Members eaten',
                                      'eating',
                                      stats.currentMeal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Row 2: On Leave & Skipped
                            Row(
                              children: [
                                Expanded(
                                  child: _ModernStatCard(
                                    title: 'On Leave',
                                    subtitle: mealTag.isNotEmpty
                                        ? mealTag.substring(3)
                                        : '',
                                    value: onLeave.toString(),
                                    icon: Icons.beach_access_rounded,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFB347),
                                        Color(0xFFFFCC33)
                                      ],
                                    ),
                                    onTap: () => _showMembersDialog(
                                      context,
                                      ref,
                                      'On leave',
                                      'leave',
                                      stats.currentMeal,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ModernStatCard(
                                    title: 'Skipped',
                                    subtitle: mealTag.isNotEmpty
                                        ? mealTag.substring(3)
                                        : '',
                                    value: skipped.toString(),
                                    icon: Icons.remove_circle_outline,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF6B9D),
                                        Color(0xFFC06C84)
                                      ],
                                    ),
                                    onTap: () => _showMembersDialog(
                                      context,
                                      ref,
                                      'Skipped',
                                      'skipped',
                                      stats.currentMeal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Daily Members Card
                            _ModernStatCard(
                              title: 'Daily Members',
                              subtitle: mealTag.isNotEmpty
                                  ? mealTag.substring(3)
                                  : '',
                              value: (stats.dailyMembers ?? 0).toString(),
                              icon: Icons.calendar_today_rounded,
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.primaryOrange,
                                  AppTheme.secondaryOrange
                                ],
                              ),
                              isWide: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Today's Menu Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.restaurant_menu,
                                color: Colors.teal,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Today's Menu",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _ModernMenuCard(
                          todaysMenu: todaysMenu,
                          onEdit: () =>
                              context.pushNamed(RouteNames.managerMenu),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Action Center Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.errorRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.pending_actions,
                                color: AppTheme.errorRed,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Action Center',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _ModernActionCenter(
                          approvals: approvals,
                          joinRequests: joinRequests,
                          onApprovePayment: (billId) async {
                            try {
                              await ref
                                  .read(dashboardRepositoryProvider)
                                  .approvePayment(billId);
                              if (context.mounted) {
                                _showSuccessSnackBar(
                                    context, 'Payment approved successfully');
                              }
                              ref.invalidate(pendingApprovalsProvider);
                            } catch (e) {
                              if (context.mounted) {
                                _showErrorSnackBar(context, 'Failed: $e');
                              }
                            }
                          },
                          onRejectPayment: (billId) async {
                            try {
                              await ref
                                  .read(dashboardRepositoryProvider)
                                  .rejectPayment(billId);
                              if (context.mounted) {
                                _showWarningSnackBar(
                                    context, 'Payment rejected');
                              }
                              ref.invalidate(pendingApprovalsProvider);
                            } catch (e) {
                              if (context.mounted) {
                                _showErrorSnackBar(context, 'Failed: $e');
                              }
                            }
                          },
                          onApproveMember: (membershipId) async {
                            try {
                              await ref
                                  .read(dashboardRepositoryProvider)
                                  .approveMembership(membershipId);
                              if (context.mounted) {
                                _showSuccessSnackBar(
                                    context, 'Member approved successfully');
                              }
                              ref.invalidate(pendingJoinRequestsProvider);
                              await ref
                                  .read(dashboardStatsProvider.notifier)
                                  .refresh();
                            } catch (e) {
                              if (context.mounted) {
                                _showErrorSnackBar(context, 'Failed: $e');
                              }
                            }
                          },
                          onRejectMember: (membershipId) async {
                            try {
                              await ref
                                  .read(dashboardRepositoryProvider)
                                  .rejectMembership(membershipId);
                              if (context.mounted) {
                                _showWarningSnackBar(
                                    context, 'Member rejected');
                              }
                              ref.invalidate(pendingJoinRequestsProvider);
                            } catch (e) {
                              if (context.mounted) {
                                _showErrorSnackBar(context, 'Failed: $e');
                              }
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future _showMembersDialog(
    BuildContext context,
    WidgetRef ref,
    String title,
    String type,
    String mealType,
  ) async {
    final effectiveMeal =
        (mealType == 'Lunch' || mealType == 'Dinner') ? mealType : 'Lunch';

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryOrange),
              SizedBox(height: 16),
              Text('Loading members...'),
            ],
          ),
        ),
      ),
    );
    final rootNav = Navigator.of(context, rootNavigator: true);

    List<Map<String, dynamic>> data;
    try {
      switch (type) {
        case 'eating':
          data = await ref
              .read(dashboardStatsProvider.notifier)
              .getMembersEating(effectiveMeal);
          break;
        case 'leave':
          data = await ref
              .read(dashboardStatsProvider.notifier)
              .getMembersOnLeave(effectiveMeal);
          break;
        case 'skipped':
          data = await ref
              .read(dashboardStatsProvider.notifier)
              .getMembersSkipped(effectiveMeal);
          break;
        case 'remaining':
          data = await ref
              .read(dashboardStatsProvider.notifier)
              .getMembersRemaining(effectiveMeal);
          break;
        default:
          data = const <Map<String, dynamic>>[];
      }

      if (!context.mounted) return;
      if (rootNav.canPop()) rootNav.pop();

      final members = data.map((m) {
        final user = (m['user'] is Map)
            ? Map<String, dynamic>.from(m['user'])
            : const <String, dynamic>{};
        final name = (user['name'] ?? '').toString();
        final phone = (user['phone'] ?? '').toString();
        return MemberInfo(name: name, phone: phone);
      }).toList();

      if (members.isEmpty) {
        _showInfoSnackBar(context, 'No members found for $effectiveMeal');
        return;
      }

      showDialog(
        context: context,
        builder: (_) => MemberDetailDialog(
          title: '$title • $effectiveMeal',
          members: members,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      if (rootNav.canPop()) rootNav.pop();
      _showErrorSnackBar(context, 'Failed: $e');
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.warningYellow,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.infoBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// Modern Live Banner Widget
class _ModernLiveBanner extends StatelessWidget {
  final DashboardStats stats;
  const _ModernLiveBanner({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isOngoing = stats.currentMeal != 'None';
    final statusText = isOngoing ? '${stats.currentMeal} Ongoing' : 'Closed';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryOrange, AppTheme.secondaryOrange],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isOngoing
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isOngoing
                                        ? Colors.greenAccent
                                        : Colors.redAccent)
                                    .withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                DateFormat('EEEE, MMMM d').format(DateTime.now()),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('y').format(DateTime.now()),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Modern Stat Card Widget
class _ModernStatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback? onTap;
  final bool isWide;

  const _ModernStatCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.gradient,
    this.onTap,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.7),
                        size: 16,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Modern Menu Card Widget
class _ModernMenuCard extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>?> todaysMenu;
  final VoidCallback onEdit;

  const _ModernMenuCard({
    required this.todaysMenu,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: todaysMenu.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryOrange),
          ),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.errorRed),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to load menu',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
        data: (menu) {
          final lunch = (menu?['lunchItems'] as List?)?.cast<String>() ??
              const <String>[];
          final dinner = (menu?['dinnerItems'] as List?)?.cast<String>() ??
              const <String>[];

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.restaurant_menu,
                            color: AppTheme.primaryOrange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Menu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (lunch.isNotEmpty || dinner.isNotEmpty) ...[
                  _buildModernMenuSection(
                    context,
                    'Lunch',
                    lunch,
                    Icons.wb_sunny_outlined,
                    const Color(0xFFFFB347),
                  ),
                  if (lunch.isNotEmpty && dinner.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child:
                          Divider(color: AppTheme.borderColor.withOpacity(0.3)),
                    ),
                  _buildModernMenuSection(
                    context,
                    'Dinner',
                    dinner,
                    Icons.nightlight_outlined,
                    const Color(0xFF667EEA),
                  ),
                ] else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.restaurant_outlined,
                            size: 48,
                            color: AppTheme.textSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No menu set for today',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernMenuSection(
    BuildContext context,
    String meal,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              meal,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// Modern Action Center Widget
class _ModernActionCenter extends StatelessWidget {
  final AsyncValue<List<Map<String, dynamic>>> approvals;
  final AsyncValue<List<Map<String, dynamic>>> joinRequests;
  final ValueChanged<String> onApprovePayment;
  final ValueChanged<String> onRejectPayment;
  final ValueChanged<String> onApproveMember;
  final ValueChanged<String> onRejectMember;

  const _ModernActionCenter({
    required this.approvals,
    required this.joinRequests,
    required this.onApprovePayment,
    required this.onRejectPayment,
    required this.onApproveMember,
    required this.onRejectMember,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment Approvals
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.payment,
                        color: Colors.teal,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Payment Approvals',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              approvals.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryOrange),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Failed to load payments: $e',
                    style: TextStyle(color: AppTheme.errorRed, fontSize: 13),
                  ),
                ),
                data: (bills) {
                  if (bills.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 48,
                              color: AppTheme.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No pending approvals',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: bills.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final bill = bills[index];
                      final billId = (bill['_id'] ?? '').toString();
                      final memberName = (bill['member']?['name'] ??
                              bill['user']?['name'] ??
                              'Member')
                          .toString();
                      final amount = (bill['amount'] ?? 0).toString();

                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.borderColor.withOpacity(0.3),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.receipt_long,
                                  color: Colors.teal,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      memberName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹$amount',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Reject',
                                    icon: const Icon(Icons.close,
                                        color: AppTheme.errorRed),
                                    onPressed: () => onRejectPayment(billId),
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          AppTheme.errorRed.withOpacity(0.1),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: 'Approve',
                                    icon: const Icon(Icons.check,
                                        color: Colors.teal),
                                    onPressed: () => onApprovePayment(billId),
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          Colors.teal.withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Join Requests
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1,
                        color: AppTheme.primaryOrange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Join Requests',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              joinRequests.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryOrange),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Failed to load join requests: $e',
                    style: TextStyle(color: AppTheme.errorRed, fontSize: 13),
                  ),
                ),
                data: (joins) {
                  if (joins.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 48,
                              color: AppTheme.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No join requests',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: joins.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final member = joins[index];
                      final membershipId = (member['_id'] ?? '').toString();
                      final uName =
                          (member['user']?['name'] ?? 'Member').toString();
                      final planName = (member['planName'] ?? '-').toString();

                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.borderColor.withOpacity(0.3),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.primaryOrange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: AppTheme.primaryOrange,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      uName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Plan: $planName',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Reject',
                                    icon: const Icon(Icons.close,
                                        color: AppTheme.errorRed),
                                    onPressed: () =>
                                        onRejectMember(membershipId),
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          AppTheme.errorRed.withOpacity(0.1),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: 'Approve',
                                    icon: const Icon(Icons.check,
                                        color: Colors.teal),
                                    onPressed: () =>
                                        onApproveMember(membershipId),
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          Colors.teal.withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Error View Widget
class _ErrorView extends StatelessWidget {
  final String message;
  final String detail;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              detail,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
