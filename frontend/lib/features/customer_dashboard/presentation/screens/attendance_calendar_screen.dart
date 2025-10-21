// lib/features/customer_dashboard/presentation/screens/attendance_calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/providers/customer_dashboard_provider.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/attendance_day.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';

class AttendanceCalendarScreen extends ConsumerStatefulWidget {
  final Membership membership;

  const AttendanceCalendarScreen({super.key, required this.membership});

  @override
  ConsumerState<AttendanceCalendarScreen> createState() =>
      _AttendanceCalendarScreenState();
}

class _AttendanceCalendarScreenState
    extends ConsumerState<AttendanceCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  void _loadAttendance() {
    ref.read(customerDashboardProvider.notifier).loadAttendance(
          _focusedDay.year,
          _focusedDay.month,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerDashboardProvider);
    final attendanceMap = _buildAttendanceMap(state.attendance);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showLegend(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar
          Card(
            margin: const EdgeInsets.all(16),
            child: TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.sunday,

              // Event loader
              eventLoader: (day) {
                final attendance = attendanceMap[_normalizeDate(day)];
                return attendance != null ? [attendance] : [];
              },

              // Calendar builders
              calendarBuilders: CalendarBuilders(
                // Marker builder for dots below dates
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return null;

                  final attendance = events.first as AttendanceDay;
                  return _buildAttendanceMarkers(attendance);
                },

                // Today builder
                todayBuilder: (context, date, focusedDay) {
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },

                // Selected builder
                selectedBuilder: (context, date, focusedDay) {
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),

              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },

              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
                _loadAttendance();
              },

              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('Attended', Colors.green),
                _buildLegendItem('Missed', Colors.red),
                _buildLegendItem('Upcoming', Colors.blue),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Selected day details
          if (_selectedDay != null) _buildDayDetails(attendanceMap),

          // Monthly stats
          _buildMonthlyStats(state.attendance),
        ],
      ),
    );
  }

  // Build attendance markers (dots) below dates
  Widget _buildAttendanceMarkers(AttendanceDay attendance) {
    return Positioned(
      bottom: 4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (attendance.hasLunchPlan)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: attendance.lunchAttended ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          if (attendance.hasDinnerPlan)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: attendance.dinnerAttended ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildDayDetails(Map<String, AttendanceDay> attendanceMap) {
    final attendance = attendanceMap[_normalizeDate(_selectedDay!)];
    if (attendance == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No data for this day'),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMMM d, y').format(_selectedDay!),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            if (attendance.hasLunchPlan)
              _buildMealStatus('Lunch', attendance.lunchAttended),
            if (attendance.hasLunchPlan && attendance.hasDinnerPlan)
              const SizedBox(height: 8),
            if (attendance.hasDinnerPlan)
              _buildMealStatus('Dinner', attendance.dinnerAttended),
          ],
        ),
      ),
    );
  }

  Widget _buildMealStatus(String mealType, bool attended) {
    return Row(
      children: [
        Icon(
          attended ? Icons.check_circle : Icons.cancel,
          color: attended ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text('$mealType: ${attended ? "Attended" : "Missed"}'),
      ],
    );
  }

  Widget _buildMonthlyStats(List<AttendanceDay> attendance) {
    final totalMeals = attendance.fold<int>(
      0,
      (sum, day) => sum + day.totalMealsCount,
    );
    final attendedMeals = attendance.fold<int>(
      0,
      (sum, day) => sum + day.attendanceCount,
    );
    final percentage = totalMeals > 0
        ? (attendedMeals / totalMeals * 100).toStringAsFixed(1)
        : '0.0';

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'This Month',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Total', totalMeals.toString()),
                _buildStatColumn('Attended', attendedMeals.toString()),
                _buildStatColumn(
                    'Missed', (totalMeals - attendedMeals).toString()),
                _buildStatColumn('Rate', '$percentage%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showLegend(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attendance Legend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegendItem('Green dot = Meal attended', Colors.green),
            const SizedBox(height: 8),
            _buildLegendItem('Red dot = Meal missed', Colors.red),
            const SizedBox(height: 8),
            const Text(
              'Note: Each date can have up to 2 dots (Lunch & Dinner) depending on your meal plan.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Map<String, AttendanceDay> _buildAttendanceMap(
      List<AttendanceDay> attendance) {
    return {
      for (var day in attendance) _normalizeDate(day.date): day,
    };
  }

  String _normalizeDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
