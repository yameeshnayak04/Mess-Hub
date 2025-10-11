import 'package:flutter/material.dart';

class MemberListScreen extends StatelessWidget {
  const MemberListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Members')),
      body: const Center(
        child: Text('Member list UI will be built here.'),
      ),
    );
  }
}
