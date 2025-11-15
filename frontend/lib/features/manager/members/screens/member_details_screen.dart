// lib/features/manager/members/screens/member_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/manager_members_providers.dart';

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

class _MemberDetailsScreenState extends ConsumerState<MemberDetailsScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<String> _mealsFromPlan(String planName) {
    final p = planName.toLowerCase();
    if (p.contains('both')) return const ['Lunch', 'Dinner'];
    if (p.contains('lunch')) return const ['Lunch'];
    if (p.contains('dinner')) return const ['Dinner'];
    return const ['Lunch', 'Dinner'];
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
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(memberDetailsProvider(widget.membershipId));
    final params = MemberCalendarParams(
      widget.membershipId,
      _focusedDay.month,
      _focusedDay.year,
    );
    final attendanceAsync = ref.watch(memberAttendanceProvider(params));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Member Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(memberDetailsProvider(widget.membershipId));
              ref.invalidate(memberAttendanceProvider(params));
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: detailsAsync.when(
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(error),
        data: (details) {
          final membership = details['membership'] as Map<String, dynamic>;
          final user = membership['user'] as Map<String, dynamic>;
          final planName = membership['planName'] as String? ?? '';
          final allowedMeals = _mealsFromPlan(planName);

          return attendanceAsync.when(
            loading: () => _buildContent(
              user,
              membership,
              planName,
              allowedMeals,
              const [],
              isLoading: true,
            ),
            error: (e, s) => _buildContent(
              user,
              membership,
              planName,
              allowedMeals,
              const [],
              error: e.toString(),
            ),
            data: (attendance) => _buildContent(
              user,
              membership,
              planName,
              allowedMeals,
              attendance,
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    Map<String, dynamic> user,
    Map<String, dynamic> membership,
    String planName,
    List<String> allowedMeals,
    List<Map<String, dynamic>> attendance, {
    bool isLoading = false,
    String? error,
  }) {
    final filtered = attendance.where((e) {
      final meal = (e['mealType'] as String?)?.trim();
      return meal == null || meal.isEmpty || allowedMeals.contains(meal);
    }).toList();

    final entriesByDate = _groupEntriesByDate(filtered);
    final counts = _computeCounts(filtered);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Member Info Card
          _MemberInfoCard(
            membership: membership,
            user: user,
            planName: planName,
          ),

          const SizedBox(height: 16),

          // Monthly Summary
          _MonthlySummary(counts: counts),

          const SizedBox(height: 16),

          // Attendance Calendar
          if (error != null)
            _ErrorCard(message: error)
          else if (isLoading)
            const _SectionLoading()
          else
            _AttendanceCalendarCard(
              focusedDay: _focusedDay,
              selectedDay: _selectedDay,
              calendarFormat: _calendarFormat,
              entriesByDate: entriesByDate,
              allowedMeals: allowedMeals,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              onPageChanged: (focusedDay) {
                setState(() => _focusedDay = focusedDay);
              },
              colorFor: _colorFor,
            ),

          const SizedBox(height: 16),

          // Legend
          const _Legend(),

          const SizedBox(height: 16),

          // Selected Day Details
          if (_selectedDay != null)
            _MealDetailsCard(
              selectedDate: _selectedDay!,
              entries: entriesByDate[DateTime(
                    _selectedDay!.year,
                    _selectedDay!.month,
                    _selectedDay!.day,
                  )] ??
                  [],
              allowedMeals: allowedMeals,
              colorFor: _colorFor,
            ),

          const SizedBox(height: 16),

          // Leave History
          _LeaveHistoryCard(membershipId: widget.membershipId),

          const SizedBox(height: 16),

          // Payment History
          _PaymentHistoryCard(membershipId: widget.membershipId),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Map<DateTime, List<Map<String, dynamic>>> _groupEntriesByDate(
      List<Map<String, dynamic>> entries) {
    final map = <DateTime, List<Map<String, dynamic>>>{};
    for (final e in entries) {
      try {
        final d = DateTime.parse(e['date'] as String).toLocal();
        final key = DateTime(d.year, d.month, d.day);
        map[key] = map[key] ?? [];
        map[key]!.add(e);
      } catch (err) {
        debugPrint('Error parsing entry: $err');
      }
    }
    return map;
  }

  Map<String, int> _computeCounts(List<Map<String, dynamic>> entries) {
    final result = {'present': 0, 'skipped': 0, 'leave': 0, 'absent': 0};
    for (final e in entries) {
      final status = (e['status'] as String?)?.toLowerCase();
      if (status != null && result.containsKey(status)) {
        result[status] = result[status]! + 1;
      }
    }
    return result;
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(AppTheme.primaryOrange),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
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
            Text(
              'Failed to load member details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Member Info Card
class _MemberInfoCard extends StatelessWidget {
  final Map<String, dynamic> membership;
  final Map<String, dynamic> user;
  final String planName;

  const _MemberInfoCard({
    required this.membership,
    required this.user,
    required this.planName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar and Basic Info
            Row(
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
                      _buildStatusBadge(membership['status']),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),

            // Plan and Billing Info
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: Icons.restaurant_menu_rounded,
                    label: 'Current Plan',
                    value: planName.isEmpty ? 'N/A' : planName,
                    color: AppTheme.primaryOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.currency_rupee,
                    label: 'Billing Rate',
                    value: '₹${membership['billingRate'] ?? 0}',
                    color: AppTheme.successGreen,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Joined Date (Full Width)
            _InfoTile(
              icon: Icons.calendar_today,
              label: 'Joined Date',
              value: _formatDate(membership['joinedDate']),
              color: AppTheme.infoBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color bgColor;
    IconData icon;

    switch (status?.toLowerCase()) {
      case 'active':
        bgColor = AppTheme.successGreen;
        icon = Icons.check_circle;
        break;
      case 'inactive':
        bgColor = AppTheme.errorRed;
        icon = Icons.cancel;
        break;
      case 'pending':
        bgColor = AppTheme.warningYellow;
        icon = Icons.pending;
        break;
      default:
        bgColor = Colors.grey;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: bgColor, size: 12),
          const SizedBox(width: 4),
          Text(
            status ?? 'N/A',
            style: TextStyle(
              color: bgColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = DateTime.parse(date.toString()).toLocal();
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
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
                  color: color.withOpacity(0.15),
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
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Monthly Summary (Same as Customer Attendance Calendar)
class _MonthlySummary extends StatelessWidget {
  final Map<String, int> counts;
  const _MonthlySummary({required this.counts});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    color: AppTheme.primaryOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Monthly Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStat(
                    context,
                    'Present',
                    counts['present'] ?? 0,
                    AppTheme.successGreen,
                    Icons.check_circle_rounded,
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.grey.shade200,
                ),
                Expanded(
                  child: _buildStat(
                    context,
                    'Skipped',
                    counts['skipped'] ?? 0,
                    AppTheme.warningYellow,
                    Icons.skip_next_rounded,
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.grey.shade200,
                ),
                Expanded(
                  child: _buildStat(
                    context,
                    'Leave',
                    counts['leave'] ?? 0,
                    AppTheme.infoBlue,
                    Icons.beach_access_rounded,
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.grey.shade200,
                ),
                Expanded(
                  child: _buildStat(
                    context,
                    'Absent',
                    counts['absent'] ?? 0,
                    AppTheme.errorRed,
                    Icons.cancel_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    String label,
    int value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
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
                fontSize: 11,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Attendance Calendar Card (Same design as Customer)
class _AttendanceCalendarCard extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final CalendarFormat calendarFormat;
  final Map<DateTime, List<Map<String, dynamic>>> entriesByDate;
  final List<String> allowedMeals;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(CalendarFormat) onFormatChanged;
  final Function(DateTime) onPageChanged;
  final Color Function(String?) colorFor;

  const _AttendanceCalendarCard({
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.entriesByDate,
    required this.allowedMeals,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
    required this.colorFor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: focusedDay,
          calendarFormat: calendarFormat,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          onDaySelected: onDaySelected,
          onFormatChanged: onFormatChanged,
          onPageChanged: onPageChanged,
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            todayDecoration: BoxDecoration(
              color: AppTheme.primaryOrange.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            todayTextStyle: const TextStyle(
              color: AppTheme.primaryOrange,
              fontWeight: FontWeight.bold,
            ),
            selectedDecoration: const BoxDecoration(
              color: AppTheme.primaryOrange,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            weekendTextStyle: TextStyle(
              color: AppTheme.errorRed.withOpacity(0.7),
            ),
            defaultTextStyle: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonShowsNext: false,
            titleTextStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
            formatButtonDecoration: BoxDecoration(
              color: AppTheme.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryOrange.withOpacity(0.3),
              ),
            ),
            formatButtonTextStyle: const TextStyle(
              color: AppTheme.primaryOrange,
              fontWeight: FontWeight.w600,
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
            weekdayStyle: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            weekendStyle: TextStyle(
              color: AppTheme.errorRed.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              final key = DateTime(date.year, date.month, date.day);
              final dayEntries = entriesByDate[key];
              if (dayEntries == null || dayEntries.isEmpty) {
                return null;
              }

              final lunch = dayEntries.firstWhere(
                (e) => e['mealType'] == 'Lunch',
                orElse: () => <String, dynamic>{},
              );
              final dinner = dayEntries.firstWhere(
                (e) => e['mealType'] == 'Dinner',
                orElse: () => <String, dynamic>{},
              );

              // Single-meal plan
              if (allowedMeals.length == 1) {
                final chosen = allowedMeals.first == 'Lunch' ? lunch : dinner;
                if (chosen.isEmpty) return null;
                return Positioned(
                  bottom: 2,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colorFor(chosen['status'] as String?),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorFor(chosen['status'] as String?)
                              .withOpacity(0.5),
                          blurRadius: 2,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Two-meal plan
              return Positioned(
                bottom: 2,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (lunch.isNotEmpty)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 3),
                        decoration: BoxDecoration(
                          color: colorFor(lunch['status'] as String?),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorFor(lunch['status'] as String?)
                                  .withOpacity(0.5),
                              blurRadius: 2,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    if (dinner.isNotEmpty)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colorFor(dinner['status'] as String?),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorFor(dinner['status'] as String?)
                                  .withOpacity(0.5),
                              blurRadius: 2,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Legend (Same as Customer)
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                  _buildLegendItem('Present', AppTheme.successGreen),
                  _buildLegendItem('Skipped', AppTheme.warningYellow),
                  _buildLegendItem('Leave', AppTheme.infoBlue),
                  _buildLegendItem('Absent', AppTheme.errorRed),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
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

// Meal Details Card (Same as Customer)
class _MealDetailsCard extends StatelessWidget {
  final DateTime selectedDate;
  final List<Map<String, dynamic>> entries;
  final List<String> allowedMeals;
  final Color Function(String?) colorFor;

  const _MealDetailsCard({
    required this.selectedDate,
    required this.entries,
    required this.allowedMeals,
    required this.colorFor,
  });

  @override
  Widget build(BuildContext context) {
    final lunchEntry = entries.firstWhere(
      (e) => e['mealType'] == 'Lunch',
      orElse: () => {},
    );
    final dinnerEntry = entries.firstWhere(
      (e) => e['mealType'] == 'Dinner',
      orElse: () => {},
    );

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_today_outlined,
                    size: 48,
                    color: AppTheme.textSecondary.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  DateFormat('EEEE, MMMM d').format(selectedDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No attendance records for this date',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.event_note_rounded,
                      color: AppTheme.primaryOrange,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Day Details',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        Text(
                          DateFormat('EEEE, MMM d, y').format(selectedDate),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (allowedMeals.contains('Lunch'))
                _buildMealRow(
                  context,
                  'Lunch',
                  Icons.wb_sunny_rounded,
                  lunchEntry['status'] as String?,
                  Colors.orange,
                  colorFor, // Pass colorFor function
                ),
              if (allowedMeals.contains('Lunch') &&
                  allowedMeals.contains('Dinner'))
                const SizedBox(height: 12),
              if (allowedMeals.contains('Dinner'))
                _buildMealRow(
                  context,
                  'Dinner',
                  Icons.nightlight_rounded,
                  dinnerEntry['status'] as String?,
                  Colors.indigo,
                  colorFor, // Pass colorFor function
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildMealRow(
  BuildContext context,
  String mealName,
  IconData icon,
  String? status,
  Color mealColor,
  Color Function(String?) colorFor, // Add this parameter
) {
  final color = colorFor(status); // Use the colorFor function
  final statusText = status ?? 'No data';

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: color.withOpacity(0.3),
        width: 1.5,
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: mealColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: mealColor, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mealName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            _getStatusEmoji(status),
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

String _getStatusEmoji(String? status) {
  switch (status?.toLowerCase()) {
    case 'present':
      return '✓';
    case 'skipped':
      return '⊘';
    case 'leave':
      return '🏖';
    case 'absent':
      return '✗';
    default:
      return '?';
  }
}

// Leave History Card
class _LeaveHistoryCard extends ConsumerWidget {
  final String membershipId;

  const _LeaveHistoryCard({required this.membershipId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leavesAsync = ref.watch(memberLeavesProvider(membershipId));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
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
                    color: AppTheme.infoBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.beach_access_rounded,
                    color: AppTheme.infoBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Leave History',
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
          leavesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppTheme.infoBlue),
                ),
              ),
            ),
            error: (e, s) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppTheme.errorRed.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load leave history',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e.toString(),
                    style: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.7),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            data: (leavesData) {
              // Handle both List and Map response structures
              List<Map<String, dynamic>> leaves = [];

              if (leavesData is List) {
                leaves = leavesData
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList();
              } else if (leavesData is Map) {
                // If it's wrapped in a 'leaves' key
                final dataMap = Map<String, dynamic>.from(leavesData as Map);
                final leavesList = dataMap['leaves'] as List?;
                if (leavesList != null) {
                  leaves = leavesList
                      .whereType<Map>()
                      .map((e) => Map<String, dynamic>.from(e))
                      .toList();
                }
              }

              if (leaves.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy_outlined,
                          size: 48,
                          color: AppTheme.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No leave history',
                          style: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: leaves.length > 5 ? 5 : leaves.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final leave = leaves[index];
                  return _LeaveItem(leave: leave);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LeaveItem extends StatelessWidget {
  final Map<String, dynamic> leave;

  const _LeaveItem({required this.leave});

  @override
  Widget build(BuildContext context) {
    final fromDate = leave['fromDate'] ?? leave['startDate'];
    final toDate = leave['toDate'] ?? leave['endDate'];
    final reason =
        leave['reason'] as String? ?? leave['leaveReason'] as String?;
    final status = leave['status'] as String?;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.infoBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.infoBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.infoBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_today,
              color: AppTheme.infoBlue,
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
                    Expanded(
                      child: Text(
                        '${_formatDate(fromDate)} - ${_formatDate(toDate)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (status != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getStatusColor(status).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (reason != null && reason.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.notes_rounded,
                        size: 14,
                        color: AppTheme.textSecondary.withOpacity(0.6),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          reason,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary.withOpacity(0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppTheme.successGreen;
      case 'pending':
        return AppTheme.warningYellow;
      case 'rejected':
        return AppTheme.errorRed;
      default:
        return AppTheme.infoBlue;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = DateTime.parse(date.toString()).toLocal();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (e) {
      return 'Invalid';
    }
  }
}

// Payment History Card
class _PaymentHistoryCard extends ConsumerWidget {
  final String membershipId;

  const _PaymentHistoryCard({required this.membershipId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(memberBillsProvider(membershipId));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
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
                    color: AppTheme.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.payment_rounded,
                    color: AppTheme.successGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Payment History',
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
          billsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppTheme.successGreen),
                ),
              ),
            ),
            error: (e, s) => Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Error: $e',
                style: const TextStyle(color: AppTheme.errorRed),
              ),
            ),
            data: (bills) {
              if (bills.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: AppTheme.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No payment history',
                          style: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: bills.take(5).length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final bill = bills[index];
                  return _PaymentItem(bill: bill);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PaymentItem extends StatelessWidget {
  final Map<String, dynamic> bill;

  const _PaymentItem({required this.bill});

  @override
  Widget build(BuildContext context) {
    final totalAmount = bill['totalAmount'];
    final status = bill['status'] as String?;
    final month = bill['month'];
    final year = bill['year'];

    final statusColor = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.all(14),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getStatusIcon(status),
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$month $year',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${totalAmount ?? 0}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
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
      case 'paid':
        return AppTheme.successGreen;
      case 'pending':
        return AppTheme.warningYellow;
      case 'overdue':
        return AppTheme.errorRed;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.schedule_rounded;
      case 'overdue':
        return Icons.error_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}

// Loading and Error States
class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppTheme.primaryOrange),
        ),
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.errorRed.withOpacity(0.3),
          width: 2,
        ),
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
