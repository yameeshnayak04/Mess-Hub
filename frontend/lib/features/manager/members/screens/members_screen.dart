import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryOrange,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryOrange,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Active'),
            Tab(text: 'Inactive'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search members...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingTab(),
                _buildActiveTab(),
                _buildInactiveTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    // Sample data - replace with actual API data
    final members = [
      {
        'id': '1',
        'name': 'Rahul Kumar',
        'phone': '9876543210',
        'plan': 'Lunch + Dinner',
        'joinedDate': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'id': '2',
        'name': 'Priya Sharma',
        'phone': '9876543211',
        'plan': 'Lunch Only',
        'joinedDate': DateTime.now().subtract(const Duration(days: 1)),
      },
    ];

    if (members.isEmpty) {
      return _buildEmptyState('No pending requests');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return _buildPendingMemberCard(member);
      },
    );
  }

  Widget _buildActiveTab() {
    // Sample data - replace with actual API data
    final members = [
      {
        'id': '3',
        'name': 'Amit Singh',
        'phone': '9876543212',
        'plan': 'Lunch + Dinner',
        'paymentStatus': 'Paid',
      },
      {
        'id': '4',
        'name': 'Sneha Patel',
        'phone': '9876543213',
        'plan': 'Dinner Only',
        'paymentStatus': 'Due',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return _buildActiveMemberCard(member);
      },
    );
  }

  Widget _buildInactiveTab() {
    return _buildEmptyState('No inactive members');
  }

  Widget _buildPendingMemberCard(Map<String, dynamic> member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
                  child: Text(
                    member['name'][0].toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member['name'],
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member['phone'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text(member['plan']),
                  backgroundColor: AppTheme.lightOrange,
                  labelStyle: const TextStyle(
                    color: AppTheme.primaryOrange,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Reject logic
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                      side: const BorderSide(color: AppTheme.errorRed),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Approve logic
                    },
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveMemberCard(Map<String, dynamic> member) {
    final paymentStatus = member['paymentStatus'] as String;
    final isPaid = paymentStatus == 'Paid';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
          child: Text(
            member['name'][0].toUpperCase(),
            style: const TextStyle(
              color: AppTheme.primaryOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(member['name']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member['phone']),
            const SizedBox(height: 4),
            Text(
              member['plan'],
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isPaid
                ? AppTheme.successGreen.withOpacity(0.1)
                : AppTheme.errorRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isPaid ? AppTheme.successGreen : AppTheme.errorRed,
            ),
          ),
          child: Text(
            paymentStatus,
            style: TextStyle(
              color: isPaid ? AppTheme.successGreen : AppTheme.errorRed,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () {
          // Navigate to member details
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
