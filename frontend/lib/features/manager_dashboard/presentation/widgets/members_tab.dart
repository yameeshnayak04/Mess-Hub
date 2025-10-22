// lib/features/manager_dashboard/presentation/tabs/members_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/manager_dashboard_provider.dart';
import '../screens/member_detail_screen.dart';

class MembersTab extends ConsumerWidget {
  const MembersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersProvider);
    return members.when(
      data: (rows) => ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final m = rows[i] as Map<String, dynamic>;
          final customer = m['customer'] as Map<String, dynamic>?;
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(customer?['name'] ?? 'Member'),
            subtitle: Text(customer?['phone'] ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  MemberDetailScreen(membershipId: m['_id'] as String),
            )),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }
}
