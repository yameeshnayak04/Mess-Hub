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
    // This function is correct. The formatting is done before passing the phone string here.
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

            // --- START: Phone Formatting Logic ---
            final bool hasPhone =
                (m.phone != null) && m.phone!.trim().isNotEmpty;

            String displayPhone = 'No phone';
            String? callPhone; // The number to be passed to _call

            if (hasPhone) {
              String trimmedPhone = m.phone!.trim();

              // Check if it's a 10-digit number and doesn't already start with +
              if (trimmedPhone.length == 10 && !trimmedPhone.startsWith('+')) {
                displayPhone = '+91 $trimmedPhone'; // For display in subtitle
                callPhone = '+91$trimmedPhone'; // For the call action
              } else {
                // Otherwise, use the number as-is
                displayPhone = trimmedPhone;
                callPhone = trimmedPhone;
              }
            }
            // --- END: Phone Formatting Logic ---

            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(m.name),
              // Use the formatted displayPhone
              subtitle: Text(displayPhone),
              // Use the existence of callPhone to show the button
              trailing: IconButton(
                tooltip: 'Call',
                icon: const Icon(Icons.call, color: Colors.teal),
                // Pass the formatted callPhone to the _call function
                onPressed: () => _call(callPhone!),
              ),
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
