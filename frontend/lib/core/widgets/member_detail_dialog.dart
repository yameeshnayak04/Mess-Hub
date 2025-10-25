import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MemberDetailDialog extends StatelessWidget {
  final String title;
  final List<MemberInfo> members;

  const MemberDetailDialog({
    super.key,
    required this.title,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            if (members.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No members found'),
              )
            else
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            AppTheme.primaryOrange.withOpacity(0.1),
                        child: Text(
                          member.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.primaryOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(member.name),
                      subtitle: Text(member.phone),
                      trailing: member.trailing,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MemberInfo {
  final String name;
  final String phone;
  final Widget? trailing;

  MemberInfo({
    required this.name,
    required this.phone,
    this.trailing,
  });
}
