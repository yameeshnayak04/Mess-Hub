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

  // Nullable until loaded to avoid premature "Eligible" states
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

      // Correct path: data.membership.mess.rules
      final rules = (details['membership']?['mess']?['rules'] as Map?) ?? {};

      if (mounted) {
        setState(() {
          final raw = rules['minLeaveDaysForRebate'];
          // Be tolerant to int or string from backend
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
    // Inclusive difference
    return _rangeEnd!.difference(_rangeStart!).inDays + 1;
  }

  bool get _isRebateEligible =>
      _minLeaveDaysForRebate != null &&
      _selectedDays >= _minLeaveDaysForRebate!;

  bool _isSelectable(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Only allow selecting dates strictly after today
    return day.isAfter(today);
  }

  String _formatDate(DateTime date) => DateFormat('MMM d, y').format(date);

  Future<void> _submitLeave() async {
    // Validate selection
    if (_rangeStart == null || _rangeEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a leave period')),
      );
      return;
    }

    // Guard on rules loading/missing
    if (_minLeaveDaysForRebate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fetching leave rules, please wait')),
      );
      return;
    }

    // Enforce minimum consecutive days before calling API
    if (!_isRebateEligible) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not eligible: minimum $_minLeaveDaysForRebate consecutive days required',
          ),
          backgroundColor: AppTheme.warningYellow,
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave application submitted successfully'),
          backgroundColor: AppTheme.successGreen,
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppTheme.errorRed),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final minText =
        !_rulesLoaded ? '…' : (_minLeaveDaysForRebate?.toString() ?? '…');

    return Scaffold(
      appBar: AppBar(title: const Text('Apply for Leave')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Guidelines / Rules banner
                  _GuidelinesCard(
                    minDaysText: minText,
                  ),

                  // Select period card (enhanced UX)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppTheme.primaryOrange.withOpacity(0.15),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title row
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryOrange
                                        .withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: const Icon(
                                    Icons.event,
                                    color: AppTheme.primaryOrange,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Select leave period',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const Spacer(),
                                if (_minLeaveDaysForRebate != null)
                                  _Chip(
                                    icon: Icons.timer,
                                    text: 'Min ${_minLeaveDaysForRebate} days',
                                    color: AppTheme.primaryOrange
                                        .withOpacity(0.12),
                                    textColor: AppTheme.primaryOrange,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Quick glance selected dates row
                            Row(
                              children: [
                                Expanded(
                                  child: _DateTile(
                                    label: 'Start',
                                    date: _rangeStart,
                                    placeholder: 'Pick start date',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward,
                                    color: AppTheme.textSecondary, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _DateTile(
                                    label: 'End',
                                    date: _rangeEnd,
                                    placeholder: 'Pick end date',
                                  ),
                                ),
                              ],
                            ),

                            // Calendar
                            TableCalendar(
                              firstDay: DateTime(
                                DateTime.now().year,
                                DateTime.now().month,
                                DateTime.now().day,
                              ),
                              lastDay:
                                  DateTime.now().add(const Duration(days: 180)),
                              focusedDay: _focusedDay,
                              calendarFormat: _calendarFormat,
                              rangeSelectionMode: _rangeSelectionMode,
                              rangeStartDay: _rangeStart,
                              rangeEndDay: _rangeEnd,
                              onDaySelected: (selectedDay, focusedDay) {
                                if (!_isSelectable(selectedDay)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Cannot select past dates or today'),
                                      duration: Duration(seconds: 1),
                                    ),
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
                              onPageChanged: (focusedDay) =>
                                  _focusedDay = focusedDay,
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
                                    AppTheme.primaryOrange.withOpacity(0.20),
                                todayDecoration: BoxDecoration(
                                  color:
                                      AppTheme.textSecondary.withOpacity(0.25),
                                  shape: BoxShape.circle,
                                ),
                                disabledDecoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              headerStyle: const HeaderStyle(
                                formatButtonVisible: true,
                                titleCentered: true,
                                formatButtonShowsNext: false,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Progress to eligibility bar
                            if (_rangeEnd != null)
                              _ProgressToEligibility(
                                selectedDays: _selectedDays,
                                minDays: _minLeaveDaysForRebate,
                                eligible: _isRebateEligible,
                              ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Selection Summary card
                  if (_rangeStart != null)
                    _SelectionSummary(
                      rangeStart: _rangeStart!,
                      rangeEnd: _rangeEnd,
                      selectedDays: _selectedDays,
                      isRebateEligible: _isRebateEligible,
                      minDays: _rulesLoaded && _minLeaveDaysForRebate != null
                          ? _minLeaveDaysForRebate!
                          : null,
                      formatDate: _formatDate,
                    ),
                ],
              ),
            ),
          ),

          // Submit Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
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
                icon: Icons.send,
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.lightOrange,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryOrange.withOpacity(0.15),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.primaryOrange),
              const SizedBox(width: 8),
              Text(
                'Leave Application Guidelines',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.darkOrange,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '• Leave must start from tomorrow onwards\n'
            '• Minimum $minDaysText consecutive days required for rebate\n'
            '• Requests are approved automatically when criteria are met',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.darkOrange,
                  height: 1.25,
                ),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final String placeholder;
  const _DateTile({
    required this.label,
    required this.date,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = date == null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (isEmpty ? AppTheme.textSecondary : AppTheme.primaryOrange)
              .withOpacity(isEmpty ? 0.15 : 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 16,
            color: isEmpty ? AppTheme.textSecondary : AppTheme.primaryOrange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isEmpty ? CrossAxisAlignment.start : CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEmpty ? placeholder : DateFormat('MMM d, y').format(date!),
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isEmpty
                            ? AppTheme.textSecondary
                            : AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              eligible ? Icons.check_circle : Icons.timelapse,
              size: 16,
              color: eligible ? AppTheme.successGreen : AppTheme.primaryOrange,
            ),
            const SizedBox(width: 6),
            Text(
              eligible
                  ? 'Eligible for rebate'
                  : (minDays == null
                      ? 'Calculating eligibility…'
                      : 'Select at least $minDays consecutive days'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: eligible
                        ? AppTheme.successGreen
                        : AppTheme.primaryOrange,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            if (minDays != null)
              Text(
                '${selectedDays.clamp(0, minDays!)} / $minDays days',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: minDays == null ? null : value,
            color: eligible ? AppTheme.successGreen : AppTheme.primaryOrange,
            backgroundColor:
                (eligible ? AppTheme.successGreen : AppTheme.primaryOrange)
                    .withOpacity(0.15),
          ),
        ),
      ],
    );
  }
}

class _SelectionSummary extends StatelessWidget {
  final DateTime rangeStart;
  final DateTime? rangeEnd;
  final int selectedDays;
  final bool isRebateEligible;
  final int? minDays;
  final String Function(DateTime) formatDate;

  const _SelectionSummary({
    required this.rangeStart,
    required this.rangeEnd,
    required this.selectedDays,
    required this.isRebateEligible,
    required this.minDays,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final minText = minDays == null ? '…' : '$minDays';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: isRebateEligible
            ? AppTheme.successGreen.withOpacity(0.06)
            : AppTheme.warningYellow.withOpacity(0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isRebateEligible
                ? AppTheme.successGreen.withOpacity(0.35)
                : AppTheme.warningYellow.withOpacity(0.35),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Icon(
                    isRebateEligible ? Icons.verified : Icons.info_outline,
                    color: isRebateEligible
                        ? AppTheme.successGreen
                        : AppTheme.warningYellow,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Selected Leave Period',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Dates
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _dateColumn(context, 'Start Date', rangeStart),
                  const Icon(Icons.arrow_forward,
                      color: AppTheme.textSecondary, size: 18),
                  _dateColumn(context, 'End Date', rangeEnd,
                      placeholder: 'Select end date'),
                ],
              ),

              if (rangeEnd != null) ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Days (consecutive)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '$selectedDays days',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.primaryOrange,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isRebateEligible
                        ? AppTheme.successGreen.withOpacity(0.08)
                        : AppTheme.warningYellow.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isRebateEligible
                          ? AppTheme.successGreen
                          : AppTheme.warningYellow,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isRebateEligible
                            ? Icons.check_circle
                            : Icons.info_outline,
                        color: isRebateEligible
                            ? AppTheme.successGreen
                            : AppTheme.warningYellow,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isRebateEligible
                              ? 'Eligible for rebate'
                              : 'Not eligible for rebate (minimum $minText consecutive days required)',
                          style: TextStyle(
                            color: isRebateEligible
                                ? AppTheme.successGreen
                                : AppTheme.warningYellow,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateColumn(BuildContext context, String label, DateTime? date,
      {String? placeholder}) {
    return Column(
      crossAxisAlignment:
          date != null ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          date != null ? formatDate(date) : (placeholder ?? ''),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color textColor;
  const _Chip({
    required this.icon,
    required this.text,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
