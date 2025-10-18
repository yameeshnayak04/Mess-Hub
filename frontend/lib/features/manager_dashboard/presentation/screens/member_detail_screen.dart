// lib/features/manager_dashboard/presentation/screens/member_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/providers/manager_dashboard_provider.dart';

class MemberDetailScreen extends ConsumerStatefulWidget {
  final String memberId;
  final String name;
  final String phone;
  const MemberDetailScreen(
      {super.key,
      required this.memberId,
      required this.name,
      required this.phone});
  @override
  ConsumerState<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends ConsumerState<MemberDetailScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(managerDashboardProvider.notifier)
          .fetchMemberAttendance(widget.memberId, _month);
      ref
          .read(managerDashboardProvider.notifier)
          .fetchMemberInvoices(widget.memberId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(managerDashboardProvider);
    final days = _buildCalendarDays(_month);
    final Map<DateTime, bool> eatenDays =
        (state.memberAttendance[widget.memberId] ?? {}) as Map<DateTime, bool>;
    final invoices = state.memberInvoices[widget.memberId] ?? const [];
    final hasPending = invoices
        .any((inv) => inv.status == 'due' || inv.status == 'pending_approval');

    return Scaffold(
      appBar: AppBar(title: const Text('Member Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(widget.name),
            subtitle: Text(widget.phone),
            trailing: hasPending
                ? const Chip(
                    label: Text('Payment Pending'),
                    backgroundColor: Color(0xFFFFE0E0))
                : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(
                      () => _month = DateTime(_month.year, _month.month - 1));
                  ref
                      .read(managerDashboardProvider.notifier)
                      .fetchMemberAttendance(widget.memberId, _month);
                },
              ),
              Expanded(
                  child:
                      Center(child: Text(DateFormat.yMMMM().format(_month)))),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(
                      () => _month = DateTime(_month.year, _month.month + 1));
                  ref
                      .read(managerDashboardProvider.notifier)
                      .fetchMemberAttendance(widget.memberId, _month);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _CalendarGrid(days: days, eatenDays: eatenDays),
          const SizedBox(height: 24),
          Text('Payment History',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...List.generate(invoices.length, (i) {
            final inv = invoices[i];
            return ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text('Invoice ${inv.month}/${inv.year}'),
              subtitle: Text('Status: ${inv.status}'),
              trailing: Text('₹${inv.amount.toStringAsFixed(0)}'),
            );
          }),
        ],
      ),
    );
  }

  List<DateTime> _buildCalendarDays(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final days = <DateTime>[];

    // Leading blanks to align the grid
    for (int i = 0; i < first.weekday - 1; i++) {
      days.add(first.subtract(Duration(days: first.weekday - 1 - i)));
    }
    // Current month days
    for (int d = 1; d <= last.day; d++) {
      days.add(DateTime(month.year, month.month, d));
    }
    // Trailing fillers
    while (days.length % 7 != 0) {
      days.add(days.last.add(const Duration(days: 1)));
    }
    return days;
  }
}

class _CalendarGrid extends StatelessWidget {
  final List<DateTime> days;
  final Map<DateTime, bool> eatenDays;
  const _CalendarGrid({required this.days, required this.eatenDays});

  @override
  Widget build(BuildContext context) {
    final currMonth = days.firstWhere((d) => true).month;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7, mainAxisSpacing: 6, crossAxisSpacing: 6),
      itemCount: days.length,
      itemBuilder: (_, i) {
        final d = days[i];
        final key = DateTime(d.year, d.month, d.day);
        final eaten = eatenDays[key] ?? false;
        final isCurrentMonth = d.month == currMonth;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: eaten
                ? Colors.green.withOpacity(0.15)
                : Colors.red.withOpacity(0.12),
            border: Border.all(color: eaten ? Colors.green : Colors.red),
          ),
          child: Center(
            child: Text('${d.day}',
                style: TextStyle(
                    color: isCurrentMonth ? Colors.black87 : Colors.black45)),
          ),
        );
      },
    );
  }
}
