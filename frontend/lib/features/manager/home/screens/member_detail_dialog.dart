// lib/core/widgets/member_detail_dialog.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MemberInfo {
  final String name;
  final String? phone; // nullable
  const MemberInfo({required this.name, this.phone});
}

class MemberDetailDialog extends StatelessWidget {
  final String title;
  final List<MemberInfo> members; // strongly typed
  const MemberDetailDialog(
      {super.key, required this.title, required this.members});

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.trim());
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 420),
        child: ListView.separated(
          itemCount: members.length,
          separatorBuilder: (_, __) => const Divider(height: 8),
          itemBuilder: (_, i) {
            final m = members[i];
            final hasPhone = (m.phone != null) && m.phone!.trim().isNotEmpty;
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(m.name),
              subtitle: Text(hasPhone ? m.phone! : 'No phone'),
              trailing: hasPhone
                  ? IconButton(
                      tooltip: 'Call',
                      icon: const Icon(Icons.call, color: Colors.teal),
                      onPressed: () => _call(m.phone!),
                    )
                  : null,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
