import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

class MemberDetailsScreen extends ConsumerStatefulWidget {
  final String memberId;

  const MemberDetailsScreen({
    super.key,
    required this.memberId,
  });

  @override
  ConsumerState<MemberDetailsScreen> createState() =>
      _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends ConsumerState<MemberDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sample data - replace with actual API data
  final Map<String, dynamic> _memberData = {
    'id': '1',
    'name': 'Amit Singh',
    'phone': '9876543212',
    'email': 'amit@example.com',
    'plan': 'Lunch + Dinner',
    'rate': 3000.0,
    'joinedDate': DateTime.now().subtract(const Duration(days: 60)),
    'status': 'Active',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Details'),
      ),
      body: Column(
        children: [
          // Member Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
                  child: Text(
                    _memberData['name'][0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _memberData['name'],
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  _memberData['phone'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildInfoChip(_memberData['plan']),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                        '₹${_memberData['rate'].toStringAsFixed(0)}/mo'),
                  ],
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryOrange,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryOrange,
            tabs: const [
              Tab(text: 'Info'),
              Tab(text: 'Attendance'),
              Tab(text: 'Payments'),
            ],
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(),
                _buildAttendanceTab(),
                _buildPaymentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.lightOrange,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.primaryOrange,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Membership Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow('Status', _memberData['status']),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Joined Date',
                    DateFormat('MMM d, y').format(_memberData['joinedDate']),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Plan', _memberData['plan']),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Monthly Rate',
                    '₹${_memberData['rate'].toStringAsFixed(0)}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Divider(height: 24),
                  _buildInfoRow('Phone', _memberData['phone']),
                  const SizedBox(height: 12),
                  _buildInfoRow('Email', _memberData['email']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildAttendanceTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_today,
            size: 80,
            color: AppTheme.primaryOrange,
          ),
          const SizedBox(height: 16),
          Text(
            'Attendance Calendar',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Member attendance history\nwould be displayed here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    final payments = [
      {
        'month': 10,
        'year': 2025,
        'amount': 2800.0,
        'status': 'Paid',
        'date': DateTime.now(),
      },
      {
        'month': 9,
        'year': 2025,
        'amount': 2850.0,
        'status': 'Paid',
        'date': DateTime.now().subtract(const Duration(days: 30)),
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        final monthName = DateFormat('MMMM').format(
          DateTime(payment['year'] as int, payment['month'] as int),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('$monthName ${payment['year']}'),
            subtitle: Text(
              'Paid on ${DateFormat('MMM d, y').format(payment['date'] as DateTime)}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${(payment['amount'] as double).toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryOrange,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    payment['status'] as String,
                    style: const TextStyle(
                      color: AppTheme.successGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
