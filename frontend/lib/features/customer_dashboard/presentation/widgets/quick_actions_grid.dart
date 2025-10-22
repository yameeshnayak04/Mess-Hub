// lib/features/customer_dashboard/presentation/widgets/quick_actions_grid.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/attendance_calendar_screen.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/leave_application_screen.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/billing_screen.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/screens/mess_rating_screen.dart';

class QuickActionsGrid extends StatelessWidget {
  final Membership membership;
  const QuickActionsGrid({super.key, required this.membership});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _Quick(
        icon: Icons.calendar_month,
        label: 'Attendance',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AttendanceCalendarScreen(membership: membership),
          ),
        ),
      ),
      _Quick(
        icon: Icons.beach_access,
        label: 'Apply Leave',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LeaveApplicationScreen(membership: membership),
          ),
        ),
      ),
      _Quick(
        icon: Icons.receipt_long,
        label: 'Billing',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BillingScreen(membership: membership), // FIX
          ),
        ),
      ),
      _Quick(
        icon: Icons.star,
        label: 'Rate Mess',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MessRatingScreen(membership: membership), // FIX
          ),
        ),
      ),
      _Quick(
          icon: Icons.call,
          label: 'Call Manager',
          onTap: () async {
            final uri = Uri.parse('tel:${membership.managerContact ?? ''}');
            if (await canLaunchUrl(uri)) await launchUrl(uri);
          }),
      _Quick(
          icon: Icons.exit_to_app,
          label: 'Leave',
          onTap: () {
            showDialog(
                context: context, builder: (_) => _confirmLeaveDialog(context));
          }),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (_, i) {
        final a = actions[i];
        return InkWell(
          onTap: a.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(_).colorScheme.surfaceVariant,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(a.icon, color: Theme.of(_).colorScheme.primary),
                const SizedBox(height: 8),
                Text(a.label, style: Theme.of(_).textTheme.bodySmall),
              ],
            ),
          ),
        );
      },
    );
  }

  AlertDialog _confirmLeaveDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('Leave membership?'),
      content:
          const Text('Confirm leaving this mess. Ensure dues are cleared.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // Provider call via ancestor context; handled in screens that include this widget.
            // Intentionally minimal here.
          },
          child: const Text('Leave'),
        ),
      ],
    );
  }
}

class _Quick {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _Quick({required this.icon, required this.label, required this.onTap});
}
