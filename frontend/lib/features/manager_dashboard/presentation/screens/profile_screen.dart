// lib/features/manager_dashboard/presentation/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/manager_dashboard/presentation/providers/manager_dashboard_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profile = await ref
          .read(managerDashboardProvider.notifier)
          .fetchMyMessProfile();
      _name.text = profile.name;
      _phone.text = profile.managerContact;
      _address.text = profile.address;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(managerDashboardProvider).myMessProfile;
    final rating = profile?.rating;
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title:
                Text('Rating: ${rating?.average?.toStringAsFixed(1) ?? '-'}'),
            subtitle: Text('Reviews: ${rating?.count ?? 0}'),
            trailing: const Icon(Icons.reviews_outlined),
            onTap: () => ref
                .read(managerDashboardProvider.notifier)
                .openReviews(context),
          ),
          const Divider(),
          TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Mess Name')),
          TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Manager Contact')),
          TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Address')),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () =>
                ref.read(managerDashboardProvider.notifier).updateMyMess(
                      name: _name.text.trim(),
                      managerContact: _phone.text.trim(),
                      address: _address.text.trim(),
                    ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
