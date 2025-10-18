// lib/features/manager_dashboard/presentation/tabs/members_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/providers/manager_dashboard_provider.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/screens/member_detail_screen.dart';

class MembersTab extends ConsumerStatefulWidget {
  const MembersTab({super.key});
  @override
  ConsumerState<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends ConsumerState<MembersTab>
    with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(length: 3, vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(managerDashboardProvider.notifier).fetchHomeData();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(managerDashboardProvider);
    final tabs = const ['Lunch', 'Dinner', 'Full Day'];
    final lists = tabs
        .map((t) => state.members.where((m) => m.mealPlanName == t).toList())
        .toList();

    return Column(
      children: [
        const SizedBox(height: 8),
        TabBar(
            controller: _controller,
            tabs: tabs.map((t) => Tab(text: t)).toList()),
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: List.generate(3, (i) {
              final members = lists[i];
              if (members.isEmpty)
                return const Center(child: Text('No members'));
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: members.length,
                itemBuilder: (_, idx) {
                  final m = members[idx];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: m.photoUrl != null
                            ? NetworkImage(m.photoUrl!)
                            : null,
                        child: m.photoUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(m.name),
                      subtitle: Text(m.phone),
                      trailing: Text(m.mealPlanName),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MemberDetailScreen(
                              memberId: m.id, name: m.name, phone: m.phone),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }
}
