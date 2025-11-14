// lib/features/customer/membership/screens/apply_leave_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/membership_providers.dart';
import '../providers/leave_providers.dart';

class ApplyLeaveScreen extends ConsumerStatefulWidget {
  final String membershipId;
  const ApplyLeaveScreen({super.key, required this.membershipId});

  @override
  ConsumerState<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends ConsumerState<ApplyLeaveScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;
  bool _isSubmitting = false;

  int? _minLeaveDaysForRebate;
  bool _rulesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    try {
      final details = await ref.read(
        membershipDetailsProvider(widget.membershipId).future,
      );

      final rules = (details['membership']?['mess']?['rules'] as Map?) ?? {};

      if (mounted) {
        setState(() {
          final raw = rules['minLeaveDaysForRebate'];
          _minLeaveDaysForRebate = raw is int ? raw : int.tryParse('$raw');
          _rulesLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _minLeaveDaysForRebate = null;
          _rulesLoaded = true;
        });
      }
    }
  }

  int get _selectedDays {
    if (_rangeStart == null || _rangeEnd == null) return 0;
    return _rangeEnd!.difference(_rangeStart!).inDays + 1;
  }

  bool get _isRebateEligible =>
      _minLeaveDaysForRebate != null &&
      _selectedDays >= _minLeaveDaysForRebate!;

  bool _isSelectable(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Only allow selecting dates strictly after today (tomorrow onwards)
    return day.isAfter(today);
  }

  String _formatDate(DateTime date) => DateFormat('MMM d, y').format(date);

  Future<void> _submitLeave() async {
    if (_rangeStart == null || _rangeEnd == null) {
      _showSnackBar(
        'Please select a leave period',
        AppTheme.warningYellow,
        Icons.warning_amber_rounded,
      );
      return;
    }

    if (_minLeaveDaysForRebate == null) {
      _showSnackBar(
        'Fetching leave rules, please wait',
        AppTheme.infoBlue,
        Icons.info_outline_rounded,
      );
      return;
    }

    if (!_isRebateEligible) {
      _showSnackBar(
        'Not eligible: minimum $_minLeaveDaysForRebate consecutive days required',
        AppTheme.warningYellow,
        Icons.warning_amber_rounded,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(leaveRepositoryProvider).applyLeave(
            membershipId: widget.membershipId,
            startDate: _rangeStart!,
            endDate: _rangeEnd!,
          );
      if (!mounted) return;
      _showSnackBar(
        'Leave application submitted successfully',
        AppTheme.successGreen,
        Icons.check_circle_rounded,
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      String message = 'Failed to submit leave';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] is String) {
          message = data['message'] as String;
        } else if (e.message != null && e.message!.isNotEmpty) {
          message = e.message!;
        }
      } else {
        final raw = e.toString().replaceAll('Exception: ', '');
        if (raw.isNotEmpty) message = raw;
      }
      _showSnackBar(message, AppTheme.errorRed, Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _clearSelection() {
    setState(() {
      _rangeStart = null;
      _rangeEnd = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final minText =
        !_rulesLoaded ? '…' : (_minLeaveDaysForRebate?.toString() ?? '…');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        title: const Text(
          'Apply for Leave',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_rangeStart != null || _rangeEnd != null)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: _clearSelection,
              tooltip: 'Clear selection',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Guidelines Banner
                  _GuidelinesCard(minDaysText: minText),

                  const SizedBox(height: 16),

                  // Date Selection Summary Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _DateSelectionCard(
                      rangeStart: _rangeStart,
                      rangeEnd: _rangeEnd,
                      selectedDays: _selectedDays,
                      minDays: _minLeaveDaysForRebate,
                      isRebateEligible: _isRebateEligible,
                      formatDate: _formatDate,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Calendar Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryOrange
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_month_rounded,
                                      color: AppTheme.primaryOrange,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Select Leave Period',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TableCalendar(
                              firstDay:
                                  DateTime.now().add(const Duration(days: 1)),
                              lastDay:
                                  DateTime.now().add(const Duration(days: 180)),
                              focusedDay: _focusedDay.isBefore(DateTime.now()
                                      .add(const Duration(days: 1)))
                                  ? DateTime.now().add(const Duration(days: 1))
                                  : _focusedDay,
                              calendarFormat: _calendarFormat,
                              rangeSelectionMode: _rangeSelectionMode,
                              rangeStartDay: _rangeStart,
                              rangeEndDay: _rangeEnd,
                              onDaySelected: (selectedDay, focusedDay) {
                                if (!_isSelectable(selectedDay)) {
                                  _showSnackBar(
                                    'Cannot select today or past dates. Please choose from tomorrow onwards.',
                                    AppTheme.warningYellow,
                                    Icons.warning_amber_rounded,
                                  );
                                  return;
                                }
                                setState(() {
                                  _focusedDay = focusedDay;
                                  if (_rangeStart == null ||
                                      _rangeEnd != null) {
                                    _rangeStart = selectedDay;
                                    _rangeEnd = null;
                                  } else {
                                    if (selectedDay.isBefore(_rangeStart!)) {
                                      _rangeEnd = _rangeStart;
                                      _rangeStart = selectedDay;
                                    } else {
                                      _rangeEnd = selectedDay;
                                    }
                                  }
                                });
                              },
                              onFormatChanged: (format) =>
                                  setState(() => _calendarFormat = format),
                              onPageChanged: (focusedDay) {
                                setState(() => _focusedDay = focusedDay);
                              },
                              enabledDayPredicate: _isSelectable,
                              calendarStyle: CalendarStyle(
                                rangeStartDecoration: const BoxDecoration(
                                  color: AppTheme.primaryOrange,
                                  shape: BoxShape.circle,
                                ),
                                rangeEndDecoration: const BoxDecoration(
                                  color: AppTheme.primaryOrange,
                                  shape: BoxShape.circle,
                                ),
                                rangeHighlightColor:
                                    AppTheme.primaryOrange.withOpacity(0.15),
                                todayDecoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                todayTextStyle: TextStyle(
                                  color:
                                      AppTheme.textSecondary.withOpacity(0.5),
                                ),
                                disabledDecoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                disabledTextStyle: TextStyle(
                                  color:
                                      AppTheme.textSecondary.withOpacity(0.3),
                                ),
                                outsideDaysVisible: false,
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
                                  color:
                                      AppTheme.primaryOrange.withOpacity(0.1),
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
                                  Icons.chevron_left_rounded,
                                  color: AppTheme.primaryOrange,
                                ),
                                rightChevronIcon: const Icon(
                                  Icons.chevron_right_rounded,
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
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Progress to Eligibility
                  if (_rangeEnd != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _ProgressToEligibility(
                        selectedDays: _selectedDays,
                        minDays: _minLeaveDaysForRebate,
                        eligible: _isRebateEligible,
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Helpful Tips Card
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _HelpfulTipsCard(),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Submit Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: PrimaryButton(
                text: 'Submit Leave Application',
                onPressed: (_rangeStart != null &&
                        _rangeEnd != null &&
                        _isRebateEligible)
                    ? _submitLeave
                    : null,
                isLoading: _isSubmitting,
                icon: Icons.send_rounded,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidelinesCard extends StatelessWidget {
  final String minDaysText;
  const _GuidelinesCard({required this.minDaysText});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryOrange.withOpacity(0.1),
            AppTheme.primaryOrange.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryOrange.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.primaryOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Leave Application Guidelines',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.darkOrange,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGuideline(context, 'Leave must start from tomorrow onwards'),
          const SizedBox(height: 8),
          _buildGuideline(context,
              'Minimum $minDaysText consecutive days required for rebate'),
          const SizedBox(height: 8),
          _buildGuideline(context,
              'Requests are approved automatically when criteria are met'),
        ],
      ),
    );
  }

  Widget _buildGuideline(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppTheme.primaryOrange,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.darkOrange,
                  height: 1.4,
                ),
          ),
        ),
      ],
    );
  }
}

class _DateSelectionCard extends StatelessWidget {
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final int selectedDays;
  final int? minDays;
  final bool isRebateEligible;
  final String Function(DateTime) formatDate;

  const _DateSelectionCard({
    required this.rangeStart,
    required this.rangeEnd,
    required this.selectedDays,
    required this.minDays,
    required this.isRebateEligible,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                    Icons.event_available_rounded,
                    color: AppTheme.primaryOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Selected Period',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DateBox(
                    label: 'Start Date',
                    date: rangeStart,
                    icon: Icons.login_rounded,
                    formatDate: formatDate,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppTheme.primaryOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateBox(
                    label: 'End Date',
                    date: rangeEnd,
                    icon: Icons.logout_rounded,
                    formatDate: formatDate,
                  ),
                ),
              ],
            ),
            if (rangeEnd != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
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
                        color: AppTheme.primaryOrange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Days',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$selectedDays ${selectedDays == 1 ? 'Day' : 'Days'}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: AppTheme.primaryOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (isRebateEligible)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Eligible',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final DateTime? date;
  final IconData icon;
  final String Function(DateTime) formatDate;

  const _DateBox({
    required this.label,
    required this.date,
    required this.icon,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasDate
            ? AppTheme.primaryOrange.withOpacity(0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasDate
              ? AppTheme.primaryOrange.withOpacity(0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color:
                    hasDate ? AppTheme.primaryOrange : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hasDate ? formatDate(date!) : 'Not selected',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color:
                      hasDate ? AppTheme.primaryOrange : AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProgressToEligibility extends StatelessWidget {
  final int selectedDays;
  final int? minDays;
  final bool eligible;
  const _ProgressToEligibility({
    required this.selectedDays,
    required this.minDays,
    required this.eligible,
  });

  @override
  Widget build(BuildContext context) {
    final total = (minDays ?? 0).toDouble();
    final value =
        total <= 0 ? 0.0 : (selectedDays.clamp(0, minDays ?? 0)) / total;

    return Card(
      elevation: 0,
      color: eligible
          ? AppTheme.successGreen.withOpacity(0.08)
          : AppTheme.warningYellow.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: eligible
              ? AppTheme.successGreen.withOpacity(0.3)
              : AppTheme.warningYellow.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: eligible
                        ? AppTheme.successGreen.withOpacity(0.2)
                        : AppTheme.warningYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    eligible
                        ? Icons.check_circle_rounded
                        : Icons.pending_outlined,
                    size: 20,
                    color: eligible
                        ? AppTheme.successGreen
                        : AppTheme.warningYellow,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eligible ? 'Rebate Eligible' : 'Rebate Eligibility',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        eligible
                            ? 'Your leave meets the requirements'
                            : minDays == null
                                ? 'Checking requirements…'
                                : 'Select at least $minDays consecutive days',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                if (minDays != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: eligible
                          ? AppTheme.successGreen
                          : AppTheme.warningYellow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${selectedDays.clamp(0, minDays!)}/$minDays',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: minDays == null ? null : value,
                color:
                    eligible ? AppTheme.successGreen : AppTheme.warningYellow,
                backgroundColor:
                    (eligible ? AppTheme.successGreen : AppTheme.warningYellow)
                        .withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpfulTipsCard extends StatelessWidget {
  const _HelpfulTipsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
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
                    color: AppTheme.infoBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppTheme.infoBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Helpful Tips',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTip(context, 'Plan your leave in advance for better rebates'),
            const SizedBox(height: 8),
            _buildTip(context, 'Consecutive days count for rebate eligibility'),
            const SizedBox(height: 8),
            _buildTip(context,
                'You can view your leave history in the billing section'),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.infoBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: AppTheme.infoBlue,
            size: 12,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
          ),
        ),
      ],
    );
  }
}
