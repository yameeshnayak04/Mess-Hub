import 'package:flutter/material.dart';

class BillingScreen extends StatelessWidget {
  final String membershipId;
  const BillingScreen({super.key, required this.membershipId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Billing History')),
      body: const Center(
        child: Text('Billing History UI will be built here.'),
      ),
    );
  }
}
