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
    // Error snackbar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = AttendanceCalendarParams(widget.membershipId,
          month: _focusedDay.month, year: _focusedDay.year);
      ref.listen(attendanceCalendarProvider(p), (prev, next) {
        next.whenOrNull(error: (e, st) {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(e.toString())));
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
      appBar: AppBar(
        title: const Text('Attendance Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(attendanceCalendarProvider(params)),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: AppTheme.errorRed),
                const SizedBox(height: 16),
                Text(
                  'Failed to load attendance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    e.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.refresh(attendanceCalendarProvider(params)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        },
        data: (list) {
          // Store raw entries by date
          final planName = membershipAsync.maybeWhen(
            data: (d) => (d['membership']?['planName'] as String?) ?? '',
            orElse: () => '',
          );
          final allowedMeals = _mealsFromPlan(planName);

          // Filter entries to plan meals
          final filtered = list.where((e) {
            final meal = (e['mealType'] as String?)?.trim();
            return meal == null || meal.isEmpty || allowedMeals.contains(meal);
          }).toList();

          final entriesByDate = _groupEntriesByDate(filtered);
          final counts = _computeCounts(filtered);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: Text(
                      planName.isEmpty ? 'Plan: —' : 'Plan: $planName',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: AppTheme.surfaceColor,
                  ),
                ),
              ),
              _MonthlySummary(counts: counts),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TableCalendar(
                        // existing props...
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
                          todayDecoration: BoxDecoration(
                            color: AppTheme.primaryOrange.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: AppTheme.primaryOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: true,
                          titleCentered: true,
                          formatButtonShowsNext: false,
                        ),
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, events) {
                            final key =
                                DateTime(date.year, date.month, date.day);
                            final dayEntries = entriesByDate[key];
                            if (dayEntries == null || dayEntries.isEmpty)
                              return null;

                            // Find meal entries present for the day
                            final lunch = dayEntries.firstWhere(
                              (e) => e['mealType'] == 'Lunch',
                              orElse: () => <String, dynamic>{},
                            );
                            final dinner = dayEntries.firstWhere(
                              (e) => e['mealType'] == 'Dinner',
                              orElse: () => <String, dynamic>{},
                            );

                            // Single-meal plan: one centered dot (pick whichever meal exists)
                            if (allowedMeals.length == 1) {
                              final chosen = allowedMeals.first == 'Lunch'
                                  ? lunch
                                  : dinner;
                              if (chosen.isEmpty) return null;
                              return Positioned(
                                bottom: 4,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color:
                                        _colorFor(chosen['status'] as String?),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            }

                            // Two-meal plan: left/right dots if present
                            return Positioned(
                              bottom: 4,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (lunch.isNotEmpty)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(right: 2),
                                      decoration: BoxDecoration(
                                        color: _colorFor(
                                            lunch['status'] as String?),
                                        shape: BoxShape.circle,
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
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _Legend(),
                      const SizedBox(height: 16),
                      if (_selectedDay != null)
                        _MealDetailsCard(
                          selectedDate: _selectedDay!,
                          entries: entriesByDate[DateTime(
                                _selectedDay!.year,
                                _selectedDay!.month,
                                _selectedDay!.day,
                              )] ??
                              [],
                          allowedMeals: allowedMeals, // NEW: limit rows to plan
                        ),
                      const SizedBox(height: 16),
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
        print('Error parsing entry: $err');
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
    return Container(
      padding: const EdgeInsets.all(16),
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
          Text('Monthly Summary',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(context, 'Present', counts['Present'] ?? 0,
                  AppTheme.successGreen),
              _buildStat(context, 'Skipped', counts['Skipped'] ?? 0,
                  AppTheme.warningYellow),
              _buildStat(
                  context, 'Leave', counts['Leave'] ?? 0, AppTheme.infoBlue),
              _buildStat(
                  context, 'Absent', counts['Absent'] ?? 0, AppTheme.errorRed),
            ],
          ),
        ],
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

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Legend', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
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
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 48,
                  color: AppTheme.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  DateFormat('MMMM d, y').format(selectedDate),
                  style: Theme.of(context).textTheme.titleMedium,
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.lightOrange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: AppTheme.primaryOrange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('EEEE, MMMM d, y').format(selectedDate),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const Divider(height: 24),
              if (allowedMeals.contains('Lunch'))
                _buildMealRow(context, 'Lunch', Icons.wb_sunny,
                    lunchEntry['status'] as String?),
              if (allowedMeals.contains('Lunch')) const SizedBox(height: 12),
              if (allowedMeals.contains('Dinner'))
                _buildMealRow(context, 'Dinner', Icons.nightlight,
                    dinnerEntry['status'] as String?),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealRow(
      BuildContext context, String mealName, IconData icon, String? status) {
    final color = _colorFor(status);
    final statusText = status ?? 'No data';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mealName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _getStatusEmoji(status),
              style: const TextStyle(fontSize: 16),
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
