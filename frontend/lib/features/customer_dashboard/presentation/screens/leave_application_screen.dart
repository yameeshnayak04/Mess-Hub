// lib/features/customer_dashboard/presentation/screens/leave_application_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/providers/customer_dashboard_provider.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';

class LeaveApplicationScreen extends ConsumerStatefulWidget {
  final Membership membership;

  const LeaveApplicationScreen({super.key, required this.membership});

  @override
  ConsumerState<LeaveApplicationScreen> createState() =>
      _LeaveApplicationScreenState();
}

class _LeaveApplicationScreenState
    extends ConsumerState<LeaveApplicationScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Leave'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instructions Card
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Select start and end dates by tapping on the calendar. Leave will be automatically marked for all days in the range.',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Calendar for date range selection
                  Card(
                    child: TableCalendar(
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      rangeStartDay: _startDate,
                      rangeEndDay: _endDate,
                      rangeSelectionMode: RangeSelectionMode.enforced,
                      calendarFormat: CalendarFormat.month,
                      startingDayOfWeek: StartingDayOfWeek.sunday,

                      // Range selection
                      onRangeSelected: (start, end, focusedDay) {
                        setState(() {
                          _focusedDay = focusedDay;
                          _startDate = start;
                          _endDate = end;
                        });
                      },

                      // Style
                      calendarStyle: CalendarStyle(
                        rangeStartDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        rangeEndDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        rangeHighlightColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.2),
                        withinRangeDecoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),

                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),

                      onPageChanged: (focusedDay) {
                        setState(() => _focusedDay = focusedDay);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Selected dates display
                  if (_startDate != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Period',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateBox(
                                    'Start Date',
                                    _startDate!,
                                  ),
                                ),
                                const Icon(Icons.arrow_forward),
                                Expanded(
                                  child: _buildDateBox(
                                    'End Date',
                                    _endDate ?? _startDate!,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Total Days: ${_calculateDays()}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Reason text field
                  TextField(
                    controller: _reasonController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Reason for Leave',
                      hintText:
                          'Enter the reason for your leave application...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _startDate != null &&
                              _reasonController.text.isNotEmpty
                          ? _submitLeave
                          : null,
                      icon: const Icon(Icons.send),
                      label: const Text('Submit Leave Application'),
                    ),
                  ),

                  // Error display
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        state.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildDateBox(String label, DateTime date) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('dd MMM yyyy').format(date),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  int _calculateDays() {
    if (_startDate == null) return 0;
    final end = _endDate ?? _startDate!;
    return end.difference(_startDate!).inDays + 1;
  }

  Future<void> _submitLeave() async {
    if (_startDate == null || _reasonController.text.isEmpty) {
      return;
    }

    final end = _endDate ?? _startDate!;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Leave Application'),
        content: Text(
          'Apply leave from ${DateFormat('dd MMM yyyy').format(_startDate!)} to ${DateFormat('dd MMM yyyy').format(end)}?\n\nTotal: ${_calculateDays()} days',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Submit leave
    await ref
        .read(customerDashboardProvider.notifier)
        .markLeave(_startDate!, end, _reasonController.text);

    if (!mounted) return;

    final state = ref.read(customerDashboardProvider);
    if (state.error == null) {
      // Success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave application submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      // Error is already shown in the UI
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
