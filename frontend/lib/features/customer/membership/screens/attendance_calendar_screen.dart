import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

class AttendanceCalendarScreen extends ConsumerStatefulWidget {
  final String membershipId;

  const AttendanceCalendarScreen({
    super.key,
    required this.membershipId,
  });

  @override
  ConsumerState<AttendanceCalendarScreen> createState() =>
      _AttendanceCalendarScreenState();
}

class _AttendanceCalendarScreenState
    extends ConsumerState<AttendanceCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Sample data - replace with actual API data
  final Map<DateTime, String> _attendanceData = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Load attendance data
    _loadAttendanceData();
  }

  void _loadAttendanceData() {
    // This would be replaced with actual API call
    // For now, adding sample data
    final now = DateTime.now();
    for (int i = 0; i < 15; i++) {
      final date = DateTime(now.year, now.month, i + 1);
      if (i % 3 == 0) {
        _attendanceData[date] = 'Present';
      } else if (i % 5 == 0) {
        _attendanceData[date] = 'Skipped';
      } else if (i % 7 == 0) {
        _attendanceData[date] = 'Leave';
      }
    }
  }

  Color _getColorForStatus(String status) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Calendar'),
      ),
      body: Column(
        children: [
          // Statistics Card
          Container(
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
                Text(
                  'Monthly Summary',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      'Present',
                      '12',
                      AppTheme.successGreen,
                    ),
                    _buildStatItem(
                      context,
                      'Skipped',
                      '3',
                      AppTheme.warningYellow,
                    ),
                    _buildStatItem(
                      context,
                      'Leave',
                      '2',
                      AppTheme.infoBlue,
                    ),
                    _buildStatItem(
                      context,
                      'Absent',
                      '1',
                      AppTheme.errorRed,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Calendar
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
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
                      markerDecoration: const BoxDecoration(
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
                        final dateKey =
                            DateTime(date.year, date.month, date.day);
                        final status = _attendanceData[dateKey];

                        if (status != null) {
                          return Positioned(
                            bottom: 4,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _getColorForStatus(status),
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                    ),
                  ),

                  // Legend
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Legend',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 16,
                              runSpacing: 12,
                              children: [
                                _buildLegendItem(
                                    'Present', AppTheme.successGreen),
                                _buildLegendItem(
                                    'Skipped', AppTheme.warningYellow),
                                _buildLegendItem('Leave', AppTheme.infoBlue),
                                _buildLegendItem('Absent', AppTheme.errorRed),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
        Text(label),
      ],
    );
  }
}
