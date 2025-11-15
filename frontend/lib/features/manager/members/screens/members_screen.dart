// lib/features/manager/members/screens/members_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/manager_members_providers.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});
  @override
  ConsumerState createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingMembersProvider);
    final active = ref.watch(membersByStatusProvider('Active'));
    final inactive = ref.watch(membersByStatusProvider('Inactive'));

    // lib/features/manager/members/screens/members_screen.dart

    Future _approveDiscontinue(String id) async {
      try {
        await ref.read(managerMembersRepositoryProvider).approveDiscontinue(id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Membership discontinued successfully')),
        );
        // Refresh active + inactive lists (status changes to Inactive)
        ref.invalidate(membersByStatusProvider('Active'));
        ref.invalidate(membersByStatusProvider('Inactive'));
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }

    Future _rejectDiscontinue(String id) async {
      try {
        await ref.read(managerMembersRepositoryProvider).rejectDiscontinue(id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Discontinuation request rejected')),
        );
        ref.invalidate(membersByStatusProvider('Active'));
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }

    Future<void> _approve(String id) async {
      try {
        await ref.read(managerMembersRepositoryProvider).approveMembership(id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member approved')),
        );
        ref.invalidate(pendingMembersProvider);
        ref.invalidate(membersByStatusProvider('Active'));
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }

    Future<void> _reject(String id) async {
      try {
        await ref.read(managerMembersRepositoryProvider).rejectMembership(id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member rejected')),
        );
        ref.invalidate(pendingMembersProvider);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/manager/members');
            }
          },
        ),
        title: const Text('Members'),
        bottom: TabBar(
          controller: _controller,
          labelColor: AppTheme.primaryOrange,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryOrange,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Active'),
            Tab(text: 'Inactive'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(pendingMembersProvider);
              ref.invalidate(membersByStatusProvider('Active'));
              ref.invalidate(membersByStatusProvider('Inactive'));
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _controller,
        children: [
          // Pending
          // Pending tab: join requests + discontinue requests
          pending.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.primaryOrange),
              ),
            ),
            error: (e, st) => _ErrorRetry(
              message: 'Failed to load pending members',
              detail: e.toString(),
              onRetry: () => ref.refresh(pendingMembersProvider),
            ),
            data: (pendingListRaw) {
              final pendingList = pendingListRaw.cast<Map<String, dynamic>>();

              return active.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppTheme.primaryOrange),
                  ),
                ),
                error: (e, st) => _ErrorRetry(
                  message: 'Failed to load discontinuation requests',
                  detail: e.toString(),
                  onRetry: () => ref.refresh(membersByStatusProvider('Active')),
                ),
                data: (activeListRaw) {
                  final activeList = activeListRaw.cast<Map<String, dynamic>>();
                  final discontinueList = activeList
                      .where((m) => m['leaveRequested'] == true)
                      .toList();

                  return _PendingCombinedList(
                    joinRequests: pendingList,
                    discontinueRequests: discontinueList,
                    onApproveJoin: _approve,
                    onRejectJoin: _reject,
                    onApproveDiscontinue: _approveDiscontinue,
                    onRejectDiscontinue: _rejectDiscontinue,
                  );
                },
              );
            },
          ),

          // Active
          active.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.primaryOrange),
              ),
            ),
            error: (e, st) => _ErrorRetry(
              message: 'Failed to load active members',
              detail: e.toString(),
              onRetry: () => ref.refresh(membersByStatusProvider('Active')),
            ),
            data: (list) => _MemberList(
              list: list.cast<Map<String, dynamic>>(),
              onTap: (m) =>
                  context.push('/manager/member/${m['_id']}', extra: m),
            ),
          ),

          // Inactive
          inactive.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.primaryOrange),
              ),
            ),
            error: (e, st) => _ErrorRetry(
              message: 'Failed to load inactive members',
              detail: e.toString(),
              onRetry: () => ref.refresh(membersByStatusProvider('Inactive')),
            ),
            data: (list) => _MemberList(
              list: list.cast<Map<String, dynamic>>(),
              onTap: (m) =>
                  context.push('/manager/member/${m['_id']}', extra: m),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingList extends StatelessWidget {
  final List<Map<String, dynamic>> list;
  final Future<void> Function(String id) onApprove;
  final Future<void> Function(String id) onReject;
  const _PendingList(
      {required this.list, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) return const _EmptyState(message: 'No pending requests');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final m = list[i];
        final user = m['user'] as Map<String, dynamic>?;
        final plan = m['planName'] ?? 'Plan';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                  backgroundColor: AppTheme.infoBlue.withOpacity(0.1),
                  child: Text((user?['name'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(color: AppTheme.infoBlue)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?['name'] ?? 'Unknown',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(user?['phone'] ?? 'N/A',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.textSecondary)),
                      ]),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppTheme.warningYellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.warningYellow)),
                  child: const Text('Pending',
                      style: TextStyle(
                          color: AppTheme.warningYellow,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 12),
              Text('Requested Plan: $plan'),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onReject(m['_id'] as String),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorRed,
                        side: const BorderSide(color: AppTheme.errorRed)),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: ElevatedButton(
                        onPressed: () => onApprove(m['_id'] as String),
                        child: const Text('Approve'))),
              ]),
            ]),
          ),
        );
      },
    );
  }
}

class _MemberList extends StatelessWidget {
  final List<Map<String, dynamic>> list;
  final void Function(Map<String, dynamic>) onTap;
  const _MemberList({required this.list, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) return const _EmptyState(message: 'No members found');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final m = list[i];
        final user = m['user'] as Map<String, dynamic>?;
        final status = m['status'] as String? ?? 'Unknown';
        final color =
            status == 'Active' ? AppTheme.successGreen : AppTheme.textSecondary;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () => onTap(m),
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Text((user?['name'] ?? 'U')[0].toUpperCase(),
                  style: TextStyle(color: color)),
            ),
            title: Text(user?['name'] ?? 'Unknown'),
            subtitle: Text(user?['phone'] ?? 'N/A'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4)),
              child: Text(status,
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.people_outline,
            size: 80, color: AppTheme.textSecondary.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text(message,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppTheme.textSecondary)),
      ]),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final String detail;
  final VoidCallback onRetry;
  const _ErrorRetry(
      {required this.message, required this.detail, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(detail,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry')),
        ]),
      ),
    );
  }
}

class _PendingCombinedList extends StatelessWidget {
  final List<Map<String, dynamic>> joinRequests;
  final List<Map<String, dynamic>> discontinueRequests;
  final Future<void> Function(String id) onApproveJoin;
  final Future<void> Function(String id) onRejectJoin;
  final Future<void> Function(String id) onApproveDiscontinue;
  final Future<void> Function(String id) onRejectDiscontinue;

  const _PendingCombinedList({
    required this.joinRequests,
    required this.discontinueRequests,
    required this.onApproveJoin,
    required this.onRejectJoin,
    required this.onApproveDiscontinue,
    required this.onRejectDiscontinue,
  });

  @override
  Widget build(BuildContext context) {
    if (joinRequests.isEmpty && discontinueRequests.isEmpty) {
      return const _EmptyState(message: 'No pending requests');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (joinRequests.isNotEmpty) ...[
          Text(
            'Join requests',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...joinRequests.map(
            (m) => Card(
              child: ListTile(
                title: Text((m['user']?['name'] ?? 'Unknown') as String),
                subtitle: Text((m['planName'] ?? '') as String),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.errorRed),
                      onPressed: () => onRejectJoin(m['_id'] as String),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => onApproveJoin(m['_id'] as String),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (discontinueRequests.isNotEmpty) ...[
          Text(
            'Discontinuation requests',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...discontinueRequests.map(
            (m) {
              final user = (m['user'] as Map?) ?? const {};
              final name = (user['name'] ?? 'Unknown') as String;
              return Card(
                child: ListTile(
                  title: Text(name),
                  subtitle: const Text('Requests permanent discontinuation'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: AppTheme.warningYellow),
                        onPressed: () =>
                            onRejectDiscontinue(m['_id'] as String),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: AppTheme.errorRed),
                        onPressed: () =>
                            onApproveDiscontinue(m['_id'] as String),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
