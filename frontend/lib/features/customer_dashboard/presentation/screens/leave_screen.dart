import 'package:flutter/material.dart';

class LeaveScreen extends StatelessWidget {
  final String membershipId;
  const LeaveScreen({super.key, required this.membershipId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark Leave')),
      body: const Center(
        child: Text('Leave Marking UI will be built here.'),
      ),
    );
  }
}
