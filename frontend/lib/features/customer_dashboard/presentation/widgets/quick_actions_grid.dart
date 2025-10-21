// lib/features/customer_dashboard/presentation/widgets/quick_actions_grid.dart

import 'package:flutter/material.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/attendance_calendar_screen.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/leave_application_screen.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/billing_screen.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/mess_rating_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class QuickActionsGrid extends StatelessWidget {
  final Membership membership;

  const QuickActionsGrid({super.key, required this.membership});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.calendar_month,
        label: 'Attendance',
        color: Colors.blue,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AttendanceCalendarScreen(membership: membership),
          ),
        ),
      ),
      _QuickAction(
        icon: Icons.beach_access,
        label: 'Apply Leave',
        color: Colors.orange,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LeaveApplicationScreen(membership: membership),
          ),
        ),
      ),
      _QuickAction(
        icon: Icons.receipt_long,
        label: 'Billing',
        color: Colors.green,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BillingScreen(membership: membership),
          ),
        ),
      ),
      _QuickAction(
        icon: Icons.star,
        label: 'Rate Mess',
        color: Colors.amber,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MessRatingScreen(membership: membership),
          ),
        ),
      ),
      _QuickAction(
        icon: Icons.phone,
        label: 'Call Manager',
        color: Colors.purple,
        onTap: () => _callManager(membership.managerContact),
      ),
      _QuickAction(
        icon: Icons.exit_to_app,
        label: 'Leave Mess',
        color: Colors.red,
        onTap: () => _showLeaveMembershipDialog(context),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(context, action);
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, _QuickAction action) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: action.color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callManager(String? phoneNumber) async {
    if (phoneNumber == null) return;
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showLeaveMembershipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Membership'),
        content: const Text(
          'Are you sure you want to leave this mess? Make sure all dues are cleared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              // Call leave membership API
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
