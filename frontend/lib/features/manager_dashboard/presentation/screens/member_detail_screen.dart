// lib/features/manager_dashboard/presentation/screens/member_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/entities/member_detail.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/providers/manager_dashboard_provider.dart';
import 'package:intl/intl.dart';

class MemberDetailScreen extends ConsumerStatefulWidget {
  final String membershipId;

  const MemberDetailScreen({super.key, required this.membershipId});

  @override
  ConsumerState<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends ConsumerState<MemberDetailScreen> {
  MemberDetail? _memberDetail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMemberDetail();
  }

  Future<void> _loadMemberDetail() async {
    final detail = await ref
        .read(managerDashboardProvider.notifier)
        .getMemberDetail(widget.membershipId);
    setState(() {
      _memberDetail = detail;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Member Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_memberDetail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Member Details')),
        body: const Center(child: Text('Failed to load member details')),
      );
    }

    final member = _memberDetail!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(member.customerName),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Info', icon: Icon(Icons.info_outline)),
              Tab(text: 'Attendance', icon: Icon(Icons.check_circle_outline)),
              Tab(text: 'Payments', icon: Icon(Icons.payment)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInfoTab(member),
            _buildAttendanceTab(member),
            _buildPaymentsTab(member),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab(MemberDetail member) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (member.customerPhoto != null)
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(member.customerPhoto!),
                    )
                  else
                    const CircleAvatar(
                        radius: 50, child: Icon(Icons.person, size: 50)),
                  const SizedBox(height: 16),
                  Text(
                    member.customerName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    member.customerPhone,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: const Text('Meal Plan'),
            subtitle: Text(member.planName),
          ),
          ListTile(
            leading: const Icon(Icons.currency_rupee),
            title: const Text('Monthly Fee'),
            subtitle: Text('₹${member.planPrice.toStringAsFixed(0)}'),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Member Since'),
            subtitle: Text(DateFormat.yMMMd().format(member.startedAt)),
          ),
          ListTile(
            leading: Icon(
              member.status == 'active' ? Icons.check_circle : Icons.cancel,
              color: member.status == 'active' ? Colors.green : Colors.red,
            ),
            title: const Text('Status'),
            subtitle: Text(member.status.toUpperCase()),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab(MemberDetail member) {
    if (member.attendance.isEmpty) {
      return const Center(child: Text('No attendance records yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: member.attendance.length,
      itemBuilder: (context, index) {
        final record = member.attendance[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: record.mealType == 'lunch'
                  ? Colors.orange.shade100
                  : Colors.blue.shade100,
              child: Icon(
                record.mealType == 'lunch' ? Icons.wb_sunny : Icons.nights_stay,
                color: record.mealType == 'lunch' ? Colors.orange : Colors.blue,
              ),
            ),
            title: Text(DateFormat.yMMMd().format(record.date)),
            subtitle: Text(record.mealType.toUpperCase()),
            trailing: record.isOverride
                ? const Chip(
                    label: Text('Override', style: TextStyle(fontSize: 11)),
                    avatar: Icon(Icons.admin_panel_settings, size: 16),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab(MemberDetail member) {
    if (member.payments.isEmpty) {
      return const Center(child: Text('No payment records yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: member.payments.length,
      itemBuilder: (context, index) {
        final payment = member.payments[index];
        final monthName =
            DateFormat.MMMM().format(DateTime(payment.year, payment.month));

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: payment.status == 'paid'
                  ? Colors.green.shade100
                  : payment.status == 'pending'
                      ? Colors.orange.shade100
                      : Colors.grey.shade100,
              child: Icon(
                payment.status == 'paid'
                    ? Icons.check_circle
                    : payment.status == 'pending'
                        ? Icons.hourglass_empty
                        : Icons.cancel,
                color: payment.status == 'paid'
                    ? Colors.green
                    : payment.status == 'pending'
                        ? Colors.orange
                        : Colors.grey,
              ),
            ),
            title: Text('$monthName ${payment.year}'),
            subtitle: Text(payment.status.toUpperCase()),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${payment.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (payment.paidAt != null)
                  Text(
                    DateFormat.MMMd().format(payment.paidAt!),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
            onTap: () async {
              // Download invoice
              try {
                final message = await ref
                    .read(managerDashboardProvider.notifier)
                    .downloadInvoice(payment.invoiceId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
        );
      },
    );
  }
}
