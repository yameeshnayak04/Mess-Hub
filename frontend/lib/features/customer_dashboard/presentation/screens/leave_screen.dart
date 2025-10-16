// This file contains the fully functional UI for marking a formal leave.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/providers/membership_provider.dart';
import 'package:intl/intl.dart'; // A package for date formatting

class LeaveScreen extends ConsumerStatefulWidget {
  final String membershipId;
  const LeaveScreen({super.key, required this.membershipId});

  @override
  ConsumerState<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends ConsumerState<LeaveScreen> {
  // Local state to hold the selected start and end dates.
  DateTime? _startDate;
  DateTime? _endDate;

  // Function to show the date picker and update the state.
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final now = DateTime.now();
    final initialDate = (isStartDate ? _startDate : _endDate) ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate:
          now.subtract(const Duration(days: 1)), // Cannot select past dates
      lastDate: now.add(
          const Duration(days: 60)), // Can apply for leave up to 60 days ahead
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // If end date is before the new start date, reset it.
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Function to handle the submission of the leave application.
  Future<void> _submitLeave() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select both a start and end date.')),
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
        Navigator.of(context).pop(); // Go back to the previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider to get the loading state.
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

            // Date Selection Buttons
            Row(
              children: [
                Expanded(
                  child: _DateSelector(
                    label: 'Start Date',
                    date: _startDate,
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DateSelector(
                    label: 'End Date',
                    date: _endDate,
                    onTap: () => _selectDate(context, false),
                    // Disable end date selection until a start date is chosen.
                    isEnabled: _startDate != null,
                  ),
                ),
              ],
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

// A private helper widget for the date selector UI.
class _DateSelector extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final bool isEnabled;

  const _DateSelector({
    required this.label,
    this.date,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isEnabled ? null : Colors.grey),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: isEnabled ? Colors.grey : Colors.grey.shade300)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date == null
                  ? 'Select Date'
                  : DateFormat('dd MMM, yyyy').format(date!),
              style: TextStyle(
                  fontSize: 16,
                  color: date == null ? Colors.grey.shade600 : null),
            ),
            Icon(Icons.calendar_month_outlined,
                color: isEnabled
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey),
          ],
        ),
      ),
    );
  }
}
