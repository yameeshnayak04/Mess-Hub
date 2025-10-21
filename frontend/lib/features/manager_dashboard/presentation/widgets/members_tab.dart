// lib/features/manager_dashboard/presentation/widgets/members_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/providers/manager_dashboard_provider.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/screens/member_detail_screen.dart';

class MembersTab extends ConsumerWidget {
  const MembersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(managerDashboardProvider);

    if (dashboardState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dashboardState.members.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No members yet',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dashboardState.members.length,
      itemBuilder: (context, index) {
        final member = dashboardState.members[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: member.customerPhoto != null
                ? CircleAvatar(
                    backgroundImage: NetworkImage(member.customerPhoto!))
                : const CircleAvatar(child: Icon(Icons.person)),
            title: Text(member.customerName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.customerPhone),
                const SizedBox(height: 4),
                Text(
                  '${member.planName} - ₹${member.planPrice.toStringAsFixed(0)}/month',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: Chip(
              label: Text(
                member.status.toUpperCase(),
                style: const TextStyle(fontSize: 11),
              ),
              backgroundColor: member.status == 'active'
                  ? Colors.green.shade100
                  : Colors.grey.shade200,
            ),
            isThreeLine: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MemberDetailScreen(membershipId: member.membershipId),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
