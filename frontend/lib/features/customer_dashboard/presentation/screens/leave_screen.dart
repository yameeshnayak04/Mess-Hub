// lib/features/customer_dashboard/presentation/screens/leave_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/providers/membership_provider.dart';
import 'package:intl/intl.dart';

class LeaveScreen extends ConsumerStatefulWidget {
  final String membershipId;
  const LeaveScreen({super.key, required this.membershipId});

  @override
  ConsumerState<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends ConsumerState<LeaveScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _selectDateRange(BuildContext context) async {
    final now = DateTime.now();
    final newDateRange = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(
          const Duration(days: 90)), // Can apply for leave up to 90 days ahead
    );

    if (newDateRange != null) {
      setState(() {
        _startDate = newDateRange.start;
        _endDate = newDateRange.end;
      });
    }
  }

  Future<void> _submitLeave() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date range.')),
      );
      return;
    }

    final notifier = ref.read(customerDashboardProvider.notifier);
    try {
      await notifier.markLeave(
        membershipId: widget.membershipId,
        startDate: _startDate!,
        endDate: _endDate!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Leave application submitted successfully!'),
              backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerDashboardProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Apply for Leave')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Select Leave Period',
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
                'Please select the first and last day of your leave. The rebate will be calculated based on your mess\'s rules.'),
            const SizedBox(height: 32),

            // Date Selection UI
            InkWell(
              onTap: () => _selectDateRange(context),
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Selected Dates',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _startDate == null
                          ? 'Tap to select a date range'
                          : '${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM, yyyy').format(_endDate!)}',
                      style: textTheme.titleMedium,
                    ),
                    const Icon(Icons.calendar_month_outlined,
                        color: Colors.deepOrange),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Submit Button
            state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitLeave,
                    child: const Text('Submit Application'),
                  ),
          ],
        ),
      ),
    );
  }
}
