// lib/features/auth/widgets/logout_action.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LogoutAction extends ConsumerWidget {
  final Color? iconColor;
  const LogoutAction({super.key, this.iconColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Logout',
      icon: Icon(Icons.logout, color: iconColor),
      onPressed: () async {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true)
                        .pop(); // close dialog only
                  }
                  await ref
                      .read(authProvider.notifier)
                      .logout(); // triggers router redirect
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logged out')),
                    );
                  }
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        );
        // no second logout here
      },
    );
  }
}
