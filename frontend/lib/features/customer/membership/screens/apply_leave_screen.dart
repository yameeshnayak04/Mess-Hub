// lib/features/customer/membership/screens/apply_leave_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
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
  int _minLeaveDaysForRebate = 1;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  void _loadRules() async {
    try {
      final data =
          await ref.read(membershipDetailsProvider(widget.membershipId).future);
      final rules =
          (data['membership']?['mess']?['rules'] as Map<String, dynamic>?) ??
              {};
      if (mounted) {
        setState(() {
          _minLeaveDaysForRebate =
              (rules['minLeaveDaysForRebate'] as int?) ?? 1;
        });
      }
    } catch (_) {}
  }

  int get _selectedDays {
    if (_rangeStart == null || _rangeEnd == null) return 0;
    return _rangeEnd!.difference(_rangeStart!).inDays + 1;
  }

  bool get _isRebateEligible => _selectedDays >= _minLeaveDaysForRebate;

  bool _isSelectable(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return day.isAfter(today);
  }

  Future<void> _submitLeave() async {
    if (_rangeStart == null || _rangeEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select leave dates')),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave application submitted successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply for Leave')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Instructions
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.lightOrange,
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
                            const Icon(Icons.info_outline,
                                color: AppTheme.primaryOrange),
                            const SizedBox(width: 8),
                            Text(
                              'Leave Application Guidelines',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppTheme.darkOrange,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• Leave must start from tomorrow onwards\n'
                          '• Both dates must be in the same month\n'
                          '• Minimum $_minLeaveDaysForRebate days required for rebate\n'
                          '• Automatically approved if criteria are met',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.darkOrange,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  // Calendar
                  TableCalendar(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 90)),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    rangeSelectionMode: _rangeSelectionMode,
                    rangeStartDay: _rangeStart,
                    rangeEndDay: _rangeEnd,
                    onDaySelected: (selectedDay, focusedDay) {
                      if (!_isSelectable(selectedDay)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cannot select past dates or today'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                        return;
                      }
                      setState(() {
                        _focusedDay = focusedDay;
                        if (_rangeStart == null || _rangeEnd != null) {
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
                    onPageChanged: (focusedDay) => _focusedDay = focusedDay,
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
                          AppTheme.primaryOrange.withOpacity(0.3),
                      todayDecoration: BoxDecoration(
                        color: AppTheme.textSecondary.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      disabledDecoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      formatButtonShowsNext: false,
                    ),
                  ),
                  // Selection Summary
                  if (_rangeStart != null)
                    _SelectionSummary(
                      rangeStart: _rangeStart!,
                      rangeEnd: _rangeEnd,
                      selectedDays: _selectedDays,
                      isRebateEligible: _isRebateEligible,
                      minDays: _minLeaveDaysForRebate,
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
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: PrimaryButton(
                text: 'Submit Leave Application',
                onPressed: _rangeStart != null && _rangeEnd != null
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

class _SelectionSummary extends StatelessWidget {
  final DateTime rangeStart;
  final DateTime? rangeEnd;
  final int selectedDays;
  final bool isRebateEligible;
  final int minDays;

  const _SelectionSummary({
    required this.rangeStart,
    required this.rangeEnd,
    required this.selectedDays,
    required this.isRebateEligible,
    required this.minDays,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: isRebateEligible
            ? AppTheme.successGreen.withOpacity(0.1)
            : AppTheme.warningYellow.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Selected Leave Period',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDateColumn(context, 'Start Date', rangeStart),
                  const Icon(Icons.arrow_forward),
                  _buildDateColumn(
                    context,
                    'End Date',
                    rangeEnd,
                    placeholder: 'Select end date',
                  ),
                ],
              ),
              if (rangeEnd != null) ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Days',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      '$selectedDays days',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.primaryOrange,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isRebateEligible
                        ? AppTheme.successGreen.withOpacity(0.1)
                        : AppTheme.warningYellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
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
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isRebateEligible
                              ? 'Eligible for rebate'
                              : 'Not eligible for rebate (minimum $minDays days required)',
                          style: TextStyle(
                            color: isRebateEligible
                                ? AppTheme.successGreen
                                : AppTheme.warningYellow,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
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

  Widget _buildDateColumn(BuildContext context, String label, DateTime? date,
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
          date != null
              ? DateFormat('MMM d, y').format(date)
              : (placeholder ?? ''),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
