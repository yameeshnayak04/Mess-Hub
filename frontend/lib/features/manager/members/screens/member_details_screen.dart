// lib/features/manager/members/screens/member_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/manager_members_providers.dart'; // MemberCalendarParams should be exported from here

class MemberDetailsScreen extends ConsumerStatefulWidget {
  final String membershipId;
  final Map<String, dynamic>? membership;

  const MemberDetailsScreen({
    super.key,
    required this.membershipId,
    this.membership,
  });

  @override
  ConsumerState<MemberDetailsScreen> createState() =>
      _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends ConsumerState<MemberDetailsScreen>
    with SingleTickerProviderStateMixin {
  CalendarFormat _format = CalendarFormat.month;
  DateTime _focused = DateTime.now();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(memberDetailsProvider(widget.membershipId));
    final attendanceAsync = ref.watch(
      memberAttendanceProvider(
        MemberCalendarParams(
          widget.membershipId,
          _focused.month,
          _focused.year,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: detailsAsync.when(
        data: (details) => _buildContent(context, details, attendanceAsync),
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Map<String, dynamic> details,
    AsyncValue<List<Map<String, dynamic>>> attendanceAsync,
  ) {
    final membership = details['membership'] as Map<String, dynamic>;
    final user = membership['user'] as Map<String, dynamic>;
    final recentAttendance = details['recentAttendance'] as List? ?? [];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Modern App Bar
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          backgroundColor: AppTheme.primaryOrange,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryOrange,
                    AppTheme.secondaryOrange,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -50,
                    bottom: -50,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            title: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'] ?? 'Member',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user['phone'] ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildStatusChip(membership['status']),
            ),
          ],
        ),

        // Content
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Member Info Card
                _MemberInfoCard(membership: membership, user: user),

                const SizedBox(height: 16),

                // Recent Activity
                if (recentAttendance.isNotEmpty)
                  _RecentActivityCard(attendance: recentAttendance),

                const SizedBox(height: 16),

                // Attendance Calendar
                _AttendanceCalendar(
                  membershipId: widget.membershipId,
                  attendanceAsync: attendanceAsync,
                  focused: _focused,
                  format: _format,
                  onFormatChanged: (format) => setState(() => _format = format),
                  onFocusedDayChanged: (focused) =>
                      setState(() => _focused = focused),
                ),

                const SizedBox(height: 16),

                // Monthly Summary
                attendanceAsync.when(
                  data: (attendance) =>
                      _MonthlySummaryCard(attendance: attendance),
                  loading: () => const _SectionLoading(),
                  error: (e, s) => _ErrorCard(message: e.toString()),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String? status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status?.toLowerCase()) {
      case 'active':
        bgColor = AppTheme.successGreen;
        textColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case 'inactive':
        bgColor = AppTheme.errorRed;
        textColor = Colors.white;
        icon = Icons.cancel;
        break;
      case 'pending':
        bgColor = AppTheme.warningYellow;
        textColor = Colors.white;
        icon = Icons.pending;
        break;
      default:
        bgColor = Colors.grey;
        textColor = Colors.white;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 4),
          Text(
            status ?? 'N/A',
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryOrange.withOpacity(0.1),
            AppTheme.backgroundColor,
          ],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppTheme.primaryOrange,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => context.pop(),
            ),
          ),
          const SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(height: 16),
                _HeaderSkeleton(),
                SizedBox(height: 16),
                _SectionLoading(),
                SizedBox(height: 16),
                _SectionLoading(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryOrange.withOpacity(0.1),
            AppTheme.backgroundColor,
          ],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppTheme.primaryOrange,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => context.pop(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _ErrorCard(message: error.toString()),
            ),
          ),
        ],
      ),
    );
  }
}

// Modern Member Info Card
class _MemberInfoCard extends StatelessWidget {
  final Map<String, dynamic> membership;
  final Map<String, dynamic> user;

  const _MemberInfoCard({
    required this.membership,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppTheme.primaryOrange.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryOrange.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with Avatar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryOrange.withOpacity(0.1),
                  AppTheme.secondaryOrange.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryOrange,
                        AppTheme.secondaryOrange,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryOrange.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (user['name'] ?? 'M')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'] ?? 'Member',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 14,
                            color: AppTheme.textSecondary.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user['phone'] ?? 'N/A',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          membership['planName'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Info Grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.currency_rupee,
                        label: 'Billing Rate',
                        value: '₹${membership['billingRate'] ?? 0}',
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.calendar_today,
                        label: 'Joined Date',
                        value: _formatDate(membership['joinedDate']),
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.event_available,
                        label: 'Effective From',
                        value: _formatDate(membership['effectiveFrom']),
                        color: AppTheme.infoBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.payment,
                        label: 'Payment',
                        value: membership['paymentStatus'] ?? 'N/A',
                        color: AppTheme.warningYellow,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = DateTime.parse(date.toString());
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (e) {
      return 'Invalid Date';
    }
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Recent Activity Card
class _RecentActivityCard extends StatelessWidget {
  final List<dynamic> attendance;

  const _RecentActivityCard({required this.attendance});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryOrange,
                        AppTheme.secondaryOrange,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryOrange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.history,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: attendance.take(5).length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = attendance[index];
              return _ActivityItem(activity: item);
            },
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    final status = activity['status'] as String?;
    final mealType = activity['mealType'] as String?;
    final date = activity['date'];

    Color statusColor = _getStatusColor(status);
    IconData statusIcon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mealType ?? 'Meal',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(date),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status ?? 'N/A',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'present':
        return AppTheme.successGreen;
      case 'leave':
        return AppTheme.infoBlue;
      case 'skipped':
        return AppTheme.warningYellow;
      case 'absent':
        return AppTheme.errorRed;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'present':
        return Icons.check_circle_rounded;
      case 'leave':
        return Icons.beach_access_rounded;
      case 'skipped':
        return Icons.skip_next_rounded;
      case 'absent':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = DateTime.parse(date.toString()).toLocal();
      return DateFormat('dd MMM, hh:mm a').format(dt);
    } catch (e) {
      return 'Invalid Date';
    }
  }
}

// Attendance Calendar with Modern Design
class _AttendanceCalendar extends StatelessWidget {
  final String membershipId;
  final AsyncValue<List<Map<String, dynamic>>> attendanceAsync;
  final DateTime focused;
  final CalendarFormat format;
  final Function(CalendarFormat) onFormatChanged;
  final Function(DateTime) onFocusedDayChanged;

  const _AttendanceCalendar({
    required this.membershipId,
    required this.attendanceAsync,
    required this.focused,
    required this.format,
    required this.onFormatChanged,
    required this.onFocusedDayChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryOrange,
                        AppTheme.secondaryOrange,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryOrange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Attendance Calendar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          attendanceAsync.when(
            data: (attendance) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TableCalendar(
                    firstDay: DateTime(focused.year, focused.month, 1),
                    lastDay: DateTime(focused.year, focused.month + 1, 0),
                    focusedDay: focused,
                    calendarFormat: format,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      formatButtonShowsNext: false,
                      formatButtonDecoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      formatButtonTextStyle: const TextStyle(
                        color: AppTheme.primaryOrange,
                        fontWeight: FontWeight.w600,
                      ),
                      titleTextStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      leftChevronIcon: const Icon(
                        Icons.chevron_left,
                        color: AppTheme.primaryOrange,
                      ),
                      rightChevronIcon: const Icon(
                        Icons.chevron_right,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary.withOpacity(0.7),
                      ),
                      weekendStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryOrange.withOpacity(0.7),
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      todayDecoration: BoxDecoration(
                        color: AppTheme.infoBlue.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: const TextStyle(
                        color: AppTheme.infoBlue,
                        fontWeight: FontWeight.bold,
                      ),
                      defaultTextStyle: const TextStyle(
                        color: AppTheme.textPrimary,
                      ),
                      weekendTextStyle: TextStyle(
                        color: AppTheme.primaryOrange.withOpacity(0.7),
                      ),
                      selectedDecoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryOrange,
                            AppTheme.secondaryOrange,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    onFormatChanged: onFormatChanged,
                    onPageChanged: onFocusedDayChanged,
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        return _DayCell(
                          day: day,
                          attendance: attendance,
                        );
                      },
                      todayBuilder: (context, day, focusedDay) {
                        return _DayCell(
                          day: day,
                          attendance: attendance,
                          isToday: true,
                        );
                      },
                    ),
                  ),
                ),
                _LegendRow(),
                const SizedBox(height: 16),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: _SectionLoading(),
            ),
            error: (e, s) => Padding(
              padding: const EdgeInsets.all(16),
              child: _ErrorCard(message: e.toString()),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final List<Map<String, dynamic>> attendance;
  final bool isToday;

  const _DayCell({
    required this.day,
    required this.attendance,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    final dayMeals = attendance.where((a) {
      try {
        final dateStr = a['date'].toString();
        final attDate = DateTime.parse(dateStr).toLocal();
        final attDay = DateTime(attDate.year, attDate.month, attDate.day);
        final checkDay = DateTime(day.year, day.month, day.day);

        return attDay.year == checkDay.year &&
            attDay.month == checkDay.month &&
            attDay.day == checkDay.day;
      } catch (e) {
        return false;
      }
    }).toList();

    if (dayMeals.isEmpty) {
      return Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: isToday
              ? BoxDecoration(
                  color: AppTheme.infoBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.infoBlue,
                    width: 2,
                  ),
                )
              : null,
          child: Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: isToday ? AppTheme.infoBlue : AppTheme.textPrimary,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isToday
                  ? AppTheme.infoBlue.withOpacity(0.1)
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: isToday
                  ? Border.all(color: AppTheme.infoBlue, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: isToday ? AppTheme.infoBlue : AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: dayMeals.map((meal) {
                final status = meal['status'] as String?;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _colorFor(status),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _colorFor(status).withOpacity(0.5),
                          blurRadius: 2,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(String? status) {
    switch (status?.toLowerCase()) {
      case 'present':
        return AppTheme.successGreen;
      case 'leave':
        return AppTheme.infoBlue;
      case 'skipped':
        return AppTheme.warningYellow;
      case 'absent':
        return AppTheme.errorRed;
      default:
        return Colors.grey;
    }
  }
}

class _LegendRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.primaryOrange,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Status Legend',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 20,
            runSpacing: 12,
            children: [
              _LegendItem(
                color: AppTheme.successGreen,
                label: 'Present',
                icon: Icons.check_circle_rounded,
              ),
              _LegendItem(
                color: AppTheme.infoBlue,
                label: 'Leave',
                icon: Icons.beach_access_rounded,
              ),
              _LegendItem(
                color: AppTheme.warningYellow,
                label: 'Skipped',
                icon: Icons.skip_next_rounded,
              ),
              _LegendItem(
                color: AppTheme.errorRed,
                label: 'Absent',
                icon: Icons.cancel_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final IconData icon;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

// Monthly Summary Card
class _MonthlySummaryCard extends StatelessWidget {
  final List<Map<String, dynamic>> attendance;

  const _MonthlySummaryCard({required this.attendance});

  @override
  Widget build(BuildContext context) {
    final counts = _monthlyCounts(attendance);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryOrange,
            AppTheme.secondaryOrange,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryOrange.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Monthly Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryTile(
                        icon: Icons.check_circle_rounded,
                        label: 'Present',
                        value: '${counts['present'] ?? 0}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryTile(
                        icon: Icons.beach_access_rounded,
                        label: 'Leave',
                        value: '${counts['leave'] ?? 0}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryTile(
                        icon: Icons.skip_next_rounded,
                        label: 'Skipped',
                        value: '${counts['skipped'] ?? 0}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryTile(
                        icon: Icons.cancel_rounded,
                        label: 'Absent',
                        value: '${counts['absent'] ?? 0}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper Functions
Map<String, int> _monthlyCounts(List<Map<String, dynamic>> attendance) {
  final counts = <String, int>{
    'present': 0,
    'leave': 0,
    'skipped': 0,
    'absent': 0,
  };

  for (final att in attendance) {
    final status = (att['status'] as String?)?.toLowerCase();
    if (status == 'present') {
      counts['present'] = (counts['present'] ?? 0) + 1;
    } else if (status == 'leave') {
      counts['leave'] = (counts['leave'] ?? 0) + 1;
    } else if (status == 'skipped') {
      counts['skipped'] = (counts['skipped'] ?? 0) + 1;
    } else if (status == 'absent') {
      counts['absent'] = (counts['absent'] ?? 0) + 1;
    }
  }

  return counts;
}

Color _colorFor(String? status) {
  switch (status?.toLowerCase()) {
    case 'present':
    case 'eating now':
      return AppTheme.successGreen;
    case 'leave':
      return AppTheme.warningYellow;
    case 'skipped':
    case 'not eating':
      return AppTheme.errorRed;
    default:
      return Colors.grey;
  }
}

// Loading States
class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 150,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.errorRed.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorRed.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: AppTheme.errorRed,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
