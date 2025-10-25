import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_animation.dart';
import '../../../../models/mess.dart';
import '../../../auth/providers/auth_provider.dart';
import '../providers/membership_provider.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final membershipsState = ref.watch(membershipProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(membershipProvider.notifier).refresh(),
        child: authState.when(
          data: (user) {
            if (user == null) return const SizedBox();

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()}, ${user.name}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),

                  // Memberships Section
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'My Memberships',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            TextButton.icon(
                              onPressed: () => context.go('/discover'),
                              icon: const Icon(Icons.add),
                              label: const Text('Join More'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        membershipsState.when(
                          data: (memberships) {
                            if (memberships.isEmpty) {
                              return _buildEmptyState(context);
                            }

                            final activeMemberships = memberships
                                .where((m) => m.status == 'Active')
                                .toList();
                            final pendingMemberships = memberships
                                .where((m) => m.status == 'Pending')
                                .toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (activeMemberships.isNotEmpty) ...[
                                  Text(
                                    'Active (${activeMemberships.length})',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppTheme.successGreen,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...activeMemberships.map(
                                    (membership) => _buildMembershipCard(
                                      context,
                                      membership,
                                      true,
                                    ),
                                  ),
                                ],
                                if (pendingMemberships.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  Text(
                                    'Pending Approval (${pendingMemberships.length})',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppTheme.warningYellow,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...pendingMemberships.map(
                                    (membership) => _buildMembershipCard(
                                      context,
                                      membership,
                                      false,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                _buildHelpCard(context),
                              ],
                            );
                          },
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (error, stack) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: AppTheme.errorRed,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Failed to load memberships',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    error.toString(),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const LoadingAnimation(),
          error: (error, stack) => ErrorAnimation(message: error.toString()),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
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
              icon: const Icon(Icons.explore),
              label: const Text('Discover Messes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipCard(
    BuildContext context,
    membership,
    bool isActive,
  ) {
    final mess = membership.messObject;
    final messName = mess != null ? mess.messName : 'Unknown Mess';
    final messImage = mess?.messImage;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isActive
            ? () => context.go('/membership-dashboard/${membership.id}')
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Mess Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  image: messImage != null
                      ? DecorationImage(
                          image: NetworkImage(messImage),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: messImage == null
                    ? const Icon(
                        Icons.restaurant,
                        color: AppTheme.primaryOrange,
                        size: 32,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Mess Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      messName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      membership.planName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.successGreen.withOpacity(0.1)
                            : AppTheme.warningYellow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        membership.status,
                        style: TextStyle(
                          color: isActive
                              ? AppTheme.successGreen
                              : AppTheme.warningYellow,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpCard(BuildContext context) {
    return Card(
      color: AppTheme.lightOrange,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: AppTheme.primaryOrange,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tap on any active membership to view details, mark attendance, and more',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.darkOrange,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
