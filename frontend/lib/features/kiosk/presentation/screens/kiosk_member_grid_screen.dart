// lib/features/kiosk/presentation/screens/kiosk_member_grid_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/kiosk/data/models/kiosk_member_model.dart';
import 'package:mess_management_system/features/kiosk/presentation/providers/kiosk_provider.dart';
import 'package:mess_management_system/features/kiosk/presentation/screens/kiosk_pin_entry_screen.dart';

class KioskMemberGridScreen extends ConsumerStatefulWidget {
  final String messId;
  const KioskMemberGridScreen({super.key, required this.messId});

  @override
  ConsumerState<KioskMemberGridScreen> createState() =>
      _KioskMemberGridScreenState();
}

class _KioskMemberGridScreenState extends ConsumerState<KioskMemberGridScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(kioskProvider.notifier).getActiveMembers(widget.messId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kioskProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Select Member')),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(KioskState state) {
    if (state.isLoading)
      return const Center(child: CircularProgressIndicator());
    if (state.error != null)
      return Center(child: Text('Error: ${state.error}'));
    if (state.members.isEmpty) {
      return const Center(
          child: Text('All members have eaten or no members found.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        childAspectRatio: 0.9,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: state.members.length,
      itemBuilder: (context, index) {
        final member = state.members[index];
        return _MemberTile(
          member: member,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) =>
                  KioskPinEntryScreen(messId: widget.messId, member: member),
            ));
          },
        );
      },
    );
  }
}

class _MemberTile extends StatelessWidget {
  final KioskMember member;
  final VoidCallback onTap;
  const _MemberTile({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.orange.shade100,
              child: member.photoUrl == null
                  ? const Icon(Icons.person, size: 40, color: Colors.deepOrange)
                  : null,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                member.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
