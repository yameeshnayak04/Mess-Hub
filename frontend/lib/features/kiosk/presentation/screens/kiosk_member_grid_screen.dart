// lib/features/kiosk/presentation/screens/kiosk_member_grid_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/kiosk/presentation/providers/kiosk_provider.dart';
import 'package:mess_management_system/features/kiosk/presentation/screens/kiosk_pin_entry_screen.dart';

class KioskMemberGridScreen extends ConsumerWidget {
  const KioskMemberGridScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kioskState = ref.watch(kioskProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${kioskState.currentMealType.toUpperCase()} Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(kioskProvider.notifier).loadMembers(),
          ),
        ],
      ),
      body: FutureBuilder(
        future: kioskState.members.isEmpty
            ? ref.read(kioskProvider.notifier).loadMembers()
            : Future.value(),
        builder: (_, __) {
          if (kioskState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (kioskState.error != null) {
            return Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(kioskState.error!),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(kioskProvider.notifier).loadMembers(),
                      child: const Text('Retry'),
                    ),
                  ]),
            );
          }
          if (kioskState.members.isEmpty) {
            return Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle,
                        size: 80, color: Colors.green.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'All members have eaten!',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: Colors.grey),
                    ),
                  ]),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: kioskState.members.length,
            itemBuilder: (context, index) {
              final member = kioskState.members[index];
              return _MemberCard(
                member: member,
                onTap: () {
                  if ((member.membershipId).isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('No membership found for this user'),
                          backgroundColor: Colors.red),
                    );
                    return;
                  }
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => KioskPinEntryScreen(member: member)));
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final dynamic member;
  final VoidCallback onTap;
  const _MemberCard({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Stack(children: [
            member.photoUrl != null
                ? CircleAvatar(
                    radius: 40, backgroundImage: NetworkImage(member.photoUrl!))
                : CircleAvatar(
                    radius: 40,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      member.name[0].toUpperCase(),
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
          ]),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              member.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(member.phone,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          _StatusChip(status: member.status),
        ]),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'eaten' => Colors.green,
      'onLeave' => Colors.orange,
      'toggled' => Colors.red,
      _ => Colors.blue,
    };
    final label = switch (status) {
      'eaten' => 'EATEN',
      'onLeave' => 'ON LEAVE',
      'toggled' => 'SKIPPED',
      _ => 'AVAILABLE',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
