// lib/features/customer_dashboard/presentation/screens/membership_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/core/routing/app_router.dart';
import 'package:mess_management_system/features/customer_dashboard/domain/entities/membership.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/providers/membership_provider.dart';

class MembershipDetailScreen extends ConsumerWidget {
  final Membership membership;
  const MembershipDetailScreen({super.key, required this.membership});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(membership.messName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Actions',
                style: textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  _NotEatingToggle(
                    mealType: 'Lunch',
                    membershipId: membership.id,
                  ),
                  const Divider(height: 1),
                  _NotEatingToggle(
                    mealType: 'Dinner',
                    membershipId: membership.id,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Manage Membership',
                style: textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('Apply for Formal Leave'),
                    subtitle: const Text('For planned, multi-day absences'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRouter.leaveRoute,
                        arguments: {'membershipId': membership.id},
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('Billing & Payment History'),
                    subtitle: const Text('View and pay your monthly bills'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRouter.billingRoute,
                        arguments: {'membershipId': membership.id},
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A stateful helper widget for the "Not Eating" toggle to manage its own loading state.
class _NotEatingToggle extends ConsumerStatefulWidget {
  final String mealType;
  final String membershipId;
  const _NotEatingToggle({required this.mealType, required this.membershipId});

  @override
  ConsumerState<_NotEatingToggle> createState() => __NotEatingToggleState();
}

class __NotEatingToggleState extends ConsumerState<_NotEatingToggle> {
  bool _isLoading = false;

  Future<void> _onToggle(bool value) async {
    // We assume the toggle is always to mark as "Not Eating". A real app might handle both.
    setState(() => _isLoading = true);
    try {
      await ref.read(customerDashboardProvider.notifier).toggleMealSkip(
            membershipId: widget.membershipId,
            date: DateTime.now(),
            mealType: widget.mealType,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${widget.mealType} meal skip noted!'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Not Eating ${widget.mealType} Today?'),
      trailing: _isLoading
          ? const CircularProgressIndicator()
          : Switch(
              value:
                  false, // This is a one-way action, so value is always false initially
              onChanged: _onToggle,
            ),
    );
  }
}
