// lib/features/customer/membership/screens/attendance_calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_app/features/customer/membership/providers/membership_providers.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/attendance_providers.dart';

class AttendanceCalendarScreen extends ConsumerStatefulWidget {
  final String membershipId;
  const AttendanceCalendarScreen({super.key, required this.membershipId});

  @override
  ConsumerState<AttendanceCalendarScreen> createState() =>
      _AttendanceCalendarScreenState();
}

class _AttendanceCalendarScreenState
    extends ConsumerState<AttendanceCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = AttendanceCalendarParams(widget.membershipId,
          month: _focusedDay.month, year: _focusedDay.year);
      ref.listen(attendanceCalendarProvider(p), (prev, next) {
        next.whenOrNull(error: (e, st) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
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
          }
        });
      });
    });
  }

  List<String> _mealsFromPlan(String planName) {
    final p = planName.toLowerCase();
    if (p.contains('both')) return const ['Lunch', 'Dinner'];
    if (p.contains('lunch')) return const ['Lunch'];
    if (p.contains('dinner')) return const ['Dinner'];
    return const ['Lunch', 'Dinner'];
  }

  Color _colorFor(String? status) {
    switch (status) {
      case 'Present':
        return AppTheme.successGreen;
      case 'Skipped':
        return AppTheme.warningYellow;
      case 'Leave':
        return AppTheme.infoBlue;
      case 'Absent':
        return AppTheme.errorRed;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final params = AttendanceCalendarParams(
      widget.membershipId,
      month: _focusedDay.month,
      year: _focusedDay.year,
    );

    final membershipAsync =
        ref.watch(membershipDetailsProvider(widget.membershipId));
    final asyncEntries = ref.watch(attendanceCalendarProvider(params));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        title: const Text(
          'Attendance Calendar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(attendanceCalendarProvider(params)),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: asyncEntries.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppTheme.primaryOrange),
          ),
        ),
        error: (e, st) {
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
                    'Failed to load attendance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.refresh(attendanceCalendarProvider(params)),
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
          );
        },
        data: (list) {
          final planName = membershipAsync.maybeWhen(
            data: (d) => (d['membership']?['planName'] as String?) ?? '',
            orElse: () => '',
          );
          final allowedMeals = _mealsFromPlan(planName);

          final filtered = list.where((e) {
            final meal = (e['mealType'] as String?)?.trim();
            return meal == null || meal.isEmpty || allowedMeals.contains(meal);
          }).toList();

          final entriesByDate = _groupEntriesByDate(filtered);
          final counts = _computeCounts(filtered);

          return Column(
            children: [
              // Plan Badge
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryOrange.withOpacity(0.1),
                      AppTheme.primaryOrange.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryOrange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        color: AppTheme.primaryOrange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Plan',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                          Text(
                            planName.isEmpty ? 'Not Available' : planName,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryOrange,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Monthly Summary
              _MonthlySummary(counts: counts),

              // Calendar
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      // Calendar Card
                      Card(
                        margin: const EdgeInsets.all(16),
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
                            focusedDay: _focusedDay,
                            calendarFormat: _calendarFormat,
                            selectedDayPredicate: (day) =>
                                isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, focusedDay) {
                              if (!mounted) return;
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            onFormatChanged: (format) {
                              if (!mounted) return;
                              setState(() => _calendarFormat = format);
                            },
                            onPageChanged: (focusedDay) {
                              if (!mounted) return;
                              setState(() => _focusedDay = focusedDay);
                            },
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
                                  color:
                                      AppTheme.primaryOrange.withOpacity(0.3),
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
                              weekdayStyle: TextStyle(
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
                                final key =
                                    DateTime(date.year, date.month, date.day);
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
                                  final chosen = allowedMeals.first == 'Lunch'
                                      ? lunch
                                      : dinner;
                                  if (chosen.isEmpty) return null;
                                  return Positioned(
                                    bottom: 2,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _colorFor(
                                            chosen['status'] as String?),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: _colorFor(
                                                    chosen['status'] as String?)
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
                                          margin:
                                              const EdgeInsets.only(right: 3),
                                          decoration: BoxDecoration(
                                            color: _colorFor(
                                                lunch['status'] as String?),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: _colorFor(lunch['status']
                                                        as String?)
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
                                            color: _colorFor(
                                                dinner['status'] as String?),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: _colorFor(
                                                        dinner['status']
                                                            as String?)
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
                      ),

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
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Map<DateTime, List<Map<String, dynamic>>> _groupEntriesByDate(
      List<dynamic> entries) {
    final map = <DateTime, List<Map<String, dynamic>>>{};
    for (final e in entries) {
      try {
        final d = DateTime.parse(e['date'] as String).toLocal();
        final key = DateTime(d.year, d.month, d.day);
        map[key] = map[key] ?? [];
        map[key]!.add(e as Map<String, dynamic>);
      } catch (err) {
        debugPrint('Error parsing entry: $err');
      }
    }
    return map;
  }

  Map<String, int> _computeCounts(List<dynamic> entries) {
    final result = {'Present': 0, 'Skipped': 0, 'Leave': 0, 'Absent': 0};
    for (final e in entries) {
      final status = e['status'] as String?;
      if (status != null && result.containsKey(status)) {
        result[status] = result[status]! + 1;
      }
    }
    return result;
  }
}

class _MonthlySummary extends StatelessWidget {
  final Map<String, int> counts;
  const _MonthlySummary({required this.counts});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
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
                    counts['Present'] ?? 0,
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
                    counts['Skipped'] ?? 0,
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
                    counts['Leave'] ?? 0,
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
                    counts['Absent'] ?? 0,
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _MealDetailsCard extends StatelessWidget {
  final DateTime selectedDate;
  final List<Map<String, dynamic>> entries;
  final List<String> allowedMeals;

  const _MealDetailsCard({
    required this.selectedDate,
    required this.entries,
    required this.allowedMeals,
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
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealRow(
    BuildContext context,
    String mealName,
    IconData icon,
    String? status,
    Color mealColor,
  ) {
    final color = _colorFor(status);
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

  Color _colorFor(String? status) {
    switch (status) {
      case 'Present':
        return AppTheme.successGreen;
      case 'Skipped':
        return AppTheme.warningYellow;
      case 'Leave':
        return AppTheme.infoBlue;
      case 'Absent':
        return AppTheme.errorRed;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getStatusEmoji(String? status) {
    switch (status) {
      case 'Present':
        return '✓';
      case 'Skipped':
        return '⊘';
      case 'Leave':
        return '🏖';
      case 'Absent':
        return '✗';
      default:
        return '?';
    }
  }
}
