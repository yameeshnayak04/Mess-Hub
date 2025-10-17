// lib/features/customer_dashboard/presentation/screens/my_memberships_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/core/routing/app_router.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/providers/membership_provider.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/widgets/membership_card.dart';

class MyMembershipsScreen extends ConsumerStatefulWidget {
  const MyMembershipsScreen({super.key});

  @override
  ConsumerState<MyMembershipsScreen> createState() =>
      _MyMembershipsScreenState();
}

class _MyMembershipsScreenState extends ConsumerState<MyMembershipsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    // Trigger the fetchMyMemberships method to load data.
    await ref.read(customerDashboardProvider.notifier).fetchMyMemberships();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider to get the current state and rebuild when it changes.
    final state = ref.watch(customerDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Memberships'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              // TODO: Implement logout in auth_provider
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: _buildBody(state),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to the Mess Discovery screen to find new messes.
          Navigator.pushNamed(context, AppRouter.messListRoute);
        },
        label: const Text('Find a Mess'),
        icon: const Icon(Icons.search),
      ),
    );
  }

  Widget _buildBody(CustomerDashboardState state) {
    if (state.isLoading && state.memberships.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
          child: Text(
              'An error occurred: ${state.error}\nPull down to try again.'));
    }
    if (state.memberships.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'You haven\'t joined any messes yet. Tap the "Find a Mess" button to get started!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: state.memberships.length,
      itemBuilder: (context, index) {
        final membership = state.memberships[index];
        return MembershipCard(membership: membership);
      },
    );
  }
}
