import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_animation.dart';
import '../../../auth/providers/auth_provider.dart';
import '../providers/membership_provider.dart';
import '../../../../models/membership.dart';
import 'package:intl/intl.dart';

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
    final membershipsState = ref.watch(membershipProvider);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '${_greeting()}, ${ref.read(authProvider).maybeWhen(
                        data: (u) => u?.name ?? 'User',
                        orElse: () => 'User',
                      )}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(DateFormat('EEEE, MMMM d').format(DateTime.now()),
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(membershipProvider.notifier).refresh(),
        child: Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(membershipProvider);
            return state.when(
              loading: () =>
                  const LoadingAnimation(message: 'Loading memberships...'),
              error: (e, _) => Center(child: Text('$e')),
              data: (memberships) {
                final activeCount =
                    memberships.where((m) => m.status == 'Active').length;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('My Memberships',
                            style: Theme.of(context).textTheme.titleMedium),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.lightOrange,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text('$activeCount Active',
                              style: const TextStyle(
                                color: AppTheme.primaryOrange,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final m in memberships) _membershipCard(context, m),
                    const SizedBox(height: 12),
                    _hintCard(),
                  ],
                );
              },
            );
          },
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

  Widget _membershipCard(BuildContext context, Membership m) {
    final mess = m.messObject;
    final joined = m.joinedDate != null
        ? DateFormat('MMM d, y').format(m.joinedDate!)
        : '-';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/membership/${m.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.lightOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(10),
                child:
                    const Icon(Icons.flatware, color: AppTheme.primaryOrange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            mess?.messName ?? 'Mess',
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (mess?.averageRating != null) ...[
                          const Icon(Icons.star,
                              size: 16, color: Color(0xFFFFC107)),
                          const SizedBox(width: 4),
                          Text(
                            mess!.averageRating!.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _planChip(m.planName),
                        _statusChip(m.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('₹${m.billingRate.toStringAsFixed(0)}/month',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Member since: $joined',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bg = Colors.grey.shade200;
    Color fg = Colors.black87;
    if (status == 'Active') {
      bg = const Color(0xFFE6F4EA);
      fg = const Color(0xFF1E8E3E);
    } else if (status == 'Pending') {
      bg = const Color(0xFFFFF4E5);
      fg = const Color(0xFFB26A00);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Text(status,
          style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
    );
  }

  Widget _planChip(String plan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.lightOrange,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(plan,
          style: const TextStyle(
              color: AppTheme.primaryOrange, fontWeight: FontWeight.w600)),
    );
  }

  Widget _hintCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates, color: AppTheme.primaryOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tap on any membership to view attendance, bills, apply for leave, and more.',
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
