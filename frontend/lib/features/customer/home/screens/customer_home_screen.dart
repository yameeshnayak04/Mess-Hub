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

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // Get current meal status
  Map<String, dynamic> _getMealStatus(Membership membership) {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final currentMinutes = hour * 60 + minute;

    final mess = membership.messObject;
    if (mess == null) {
      return {
        'isActive': false,
        'mealType': 'none',
        'nextMeal': 'Lunch',
        'nextMealTime': '09:00 AM'
      };
    }

    // Parse lunch timings - Access MessTimings properties directly
    final lunchStart = mess.timings.lunch.start;
    final lunchEnd = mess.timings.lunch.end;
    final lunchStartMinutes = _parseTimeToMinutes(lunchStart);
    final lunchEndMinutes = _parseTimeToMinutes(lunchEnd);

    // Parse dinner timings - Access MessTimings properties directly
    final dinnerStart = mess.timings.dinner.start;
    final dinnerEnd = mess.timings.dinner.end;
    final dinnerStartMinutes = _parseTimeToMinutes(dinnerStart);
    final dinnerEndMinutes = _parseTimeToMinutes(dinnerEnd);

    final planName = membership.planName.toLowerCase();
    final hasLunch = planName.contains('both') || planName.contains('lunch');
    final hasDinner = planName.contains('both') || planName.contains('dinner');

    // Check if lunch is active
    if (hasLunch &&
        currentMinutes >= lunchStartMinutes &&
        currentMinutes < lunchEndMinutes) {
      return {
        'isActive': true,
        'mealType': 'lunch',
        'startTime': _formatTime(lunchStart),
        'endTime': _formatTime(lunchEnd),
        'lunchTiming': hasLunch
            ? '${_formatTime(lunchStart)} - ${_formatTime(lunchEnd)}'
            : null,
        'dinnerTiming': hasDinner
            ? '${_formatTime(dinnerStart)} - ${_formatTime(dinnerEnd)}'
            : null,
      };
    }

    // Check if dinner is active
    if (hasDinner &&
        currentMinutes >= dinnerStartMinutes &&
        currentMinutes < dinnerEndMinutes) {
      return {
        'isActive': true,
        'mealType': 'dinner',
        'startTime': _formatTime(dinnerStart),
        'endTime': _formatTime(dinnerEnd),
        'lunchTiming': hasLunch
            ? '${_formatTime(lunchStart)} - ${_formatTime(lunchEnd)}'
            : null,
        'dinnerTiming': hasDinner
            ? '${_formatTime(dinnerStart)} - ${_formatTime(dinnerEnd)}'
            : null,
      };
    }

    // No active meal, determine next meal
    String nextMeal = 'Lunch';
    String nextMealTime = _formatTime(lunchStart);

    if (hasLunch && currentMinutes < lunchStartMinutes) {
      nextMeal = 'Lunch';
      nextMealTime = _formatTime(lunchStart);
    } else if (hasDinner && currentMinutes < dinnerStartMinutes) {
      nextMeal = 'Dinner';
      nextMealTime = _formatTime(dinnerStart);
    } else if (hasDinner) {
      nextMeal = 'Dinner';
      nextMealTime = _formatTime(dinnerStart);
    } else if (hasLunch) {
      nextMeal = 'Lunch';
      nextMealTime = _formatTime(lunchStart);
    }

    return {
      'isActive': false,
      'mealType': 'none',
      'nextMeal': nextMeal,
      'nextMealTime': nextMealTime,
      'lunchTiming': hasLunch
          ? '${_formatTime(lunchStart)} - ${_formatTime(lunchEnd)}'
          : null,
      'dinnerTiming': hasDinner
          ? '${_formatTime(dinnerStart)} - ${_formatTime(dinnerEnd)}'
          : null,
    };
  }

  int _parseTimeToMinutes(String time) {
    try {
      final parts = time.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (_) {
      return 0;
    }
  }

  String _formatTime(String time24) {
    try {
      final parts = time24.split(':');
      int hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '$hour:$minute $period';
    } catch (_) {
      return time24;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<List<Membership>>>(membershipProvider, (prev, next) {
      next.whenOrNull(error: (e, st) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(e.toString())),
              ],
            ),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      });
    });

    final authState = ref.watch(authProvider);
    final membershipsState = ref.watch(membershipProvider);

    final String userName = authState.maybeWhen(
      data: (u) => u?.name.split(' ').first ?? 'Customer',
      orElse: () => 'Customer',
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.primaryOrange,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryOrange,
                      AppTheme.primaryOrange.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _greeting() == 'Good Morning'
                                    ? Icons.wb_sunny_rounded
                                    : _greeting() == 'Good Afternoon'
                                        ? Icons.wb_sunny_outlined
                                        : Icons.nightlight_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_greeting()},',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('EEEE, MMMM dd')
                                  .format(DateTime.now()),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: RefreshIndicator(
              color: AppTheme.primaryOrange,
              onRefresh: () => ref.read(membershipProvider.notifier).refresh(),
              child: membershipsState.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(64.0),
                  child: LoadingAnimation(message: 'Loading memberships...'),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
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
                            Icons.error_outline_rounded,
                            size: 64,
                            color: AppTheme.errorRed,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Failed to load memberships',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          e.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () =>
                              ref.read(membershipProvider.notifier).refresh(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (memberships) {
                  if (memberships.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  final activeCount =
                      memberships.where((m) => m.status == 'Active').length;

                  return Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryOrange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.restaurant_menu_rounded,
                                    size: 18,
                                    color: AppTheme.primaryOrange,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'My Memberships',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppTheme.successGreen.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.successGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$activeCount Active',
                                    style: const TextStyle(
                                      color: AppTheme.successGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Memberships List
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: memberships.length,
                        itemBuilder: (context, index) {
                          return _membershipCard(context, memberships[index]);
                        },
                      ),

                      // Hint Card
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        child: _hintCard(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height -
          200, // Give it full height minus app bar
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restaurant_outlined,
                  size: 80,
                  color: AppTheme.textSecondary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Memberships Yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Discover and join messes near you to get started',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.push('/discover'),
                icon: const Icon(Icons.explore_outlined),
                label: const Text('Discover Messes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _membershipCard(BuildContext context, Membership m) {
    final mess = m.messObject;
    final joined = m.joinedDate != null
        ? DateFormat('MMM d, y').format(m.joinedDate!)
        : '-';
    final bool isActive = m.status == 'Active';
    final mealStatus = _getMealStatus(m);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isActive
              ? () => context.push('/membership-dashboard/${m.id}')
              : null,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryOrange.withOpacity(0.2),
                            AppTheme.primaryOrange.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.restaurant_rounded,
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
                            mess?.messName ?? 'Mess',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (mess?.averageRating != null &&
                              mess!.averageRating! > 0)
                            Row(
                              children: [
                                ...List.generate(
                                  5,
                                  (index) => Icon(
                                    index < mess.averageRating!.round()
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    size: 16,
                                    color: index < mess.averageRating!.round()
                                        ? Colors.amber
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  mess.averageRating!.toStringAsFixed(1),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Meal Status Indicator
                if (isActive && mealStatus['isActive'] == true)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: mealStatus['mealType'] == 'lunch'
                            ? [
                                Colors.orange.shade50,
                                Colors.orange.shade100.withOpacity(0.5),
                              ]
                            : [
                                Colors.indigo.shade50,
                                Colors.indigo.shade100.withOpacity(0.5),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: mealStatus['mealType'] == 'lunch'
                            ? Colors.orange.shade200
                            : Colors.indigo.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: mealStatus['mealType'] == 'lunch'
                                ? Colors.orange.shade100
                                : Colors.indigo.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            mealStatus['mealType'] == 'lunch'
                                ? Icons.wb_sunny_rounded
                                : Icons.nightlight_rounded,
                            color: mealStatus['mealType'] == 'lunch'
                                ? Colors.orange.shade700
                                : Colors.indigo.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: mealStatus['mealType'] == 'lunch'
                                          ? Colors.orange.shade600
                                          : Colors.indigo.shade600,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${mealStatus['mealType'] == 'lunch' ? 'Lunch' : 'Dinner'} is Active',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: mealStatus['mealType'] == 'lunch'
                                          ? Colors.orange.shade900
                                          : Colors.indigo.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${mealStatus['startTime']} - ${mealStatus['endTime']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: mealStatus['mealType'] == 'lunch'
                                      ? Colors.orange.shade700
                                      : Colors.indigo.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isActive && mealStatus['mealType'] == 'none')
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.schedule_rounded,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Next Meal: ${mealStatus['nextMeal']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Starts at ${mealStatus['nextMealTime']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Meal Timings
                if (isActive &&
                    (mealStatus['lunchTiming'] != null ||
                        mealStatus['dinnerTiming'] != null))
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.infoBlue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.infoBlue.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: AppTheme.infoBlue.withOpacity(0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Meal Timings',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.infoBlue.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (mealStatus['lunchTiming'] != null) ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.wb_sunny_rounded,
                                  size: 14,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Lunch: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                mealStatus['lunchTiming'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          if (mealStatus['dinnerTiming'] != null)
                            const SizedBox(height: 8),
                        ],
                        if (mealStatus['dinnerTiming'] != null)
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.nightlight_rounded,
                                  size: 14,
                                  color: Colors.indigo.shade700,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Dinner: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                mealStatus['dinnerTiming'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Plan & Status Row
                Row(
                  children: [
                    _planChip(m.planName),
                    const SizedBox(width: 8),
                    _statusChip(m.status),
                  ],
                ),

                const SizedBox(height: 16),

                // Divider
                Container(
                  height: 1,
                  color: Colors.grey.shade200,
                ),

                const SizedBox(height: 16),

                // Bottom Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Rate',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${m.billingRate.toStringAsFixed(0)}',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryOrange,
                                  ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Member Since',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          joined,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bg = AppTheme.borderColor;
    Color fg = AppTheme.textSecondary;
    IconData icon = Icons.info_outline_rounded;

    if (status == 'Active') {
      bg = AppTheme.successGreen.withOpacity(0.1);
      fg = AppTheme.successGreen;
      icon = Icons.check_circle_rounded;
    } else if (status == 'Pending') {
      bg = AppTheme.warningYellow.withOpacity(0.1);
      fg = AppTheme.warningYellow;
      icon = Icons.schedule_rounded;
    } else if (status == 'Inactive') {
      bg = Colors.grey.shade200;
      fg = Colors.grey.shade700;
      icon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _planChip(String plan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryOrange.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.restaurant_menu_rounded,
            size: 14,
            color: AppTheme.primaryOrange,
          ),
          const SizedBox(width: 6),
          Text(
            plan,
            style: const TextStyle(
              color: AppTheme.primaryOrange,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hintCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.infoBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.infoBlue.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.infoBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: AppTheme.infoBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Tip',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.infoBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap on any active membership to view attendance, bills, apply for leave, and more.',
                  style: TextStyle(
                    color: AppTheme.infoBlue.withOpacity(0.8),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
