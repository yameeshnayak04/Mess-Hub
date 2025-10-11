// This screen is the main dashboard for a logged-in customer.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/providers/membership_provider.dart';
import 'package:mess_management_system/features/customer_dashboard/presentation/widgets/membership_card.dart';

// Use a ConsumerStatefulWidget to listen to providers and manage local state.
class MyMembershipsScreen extends ConsumerStatefulWidget {
  const MyMembershipsScreen({super.key});

  @override
  ConsumerState<MyMembershipsScreen> createState() =>
      _MyMembershipsScreenState();
}

class _MyMembershipsScreenState extends ConsumerState<MyMembershipsScreen> {
  // This is called once when the widget is first created.
  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to call the provider method after the first frame is built.
    // This ensures that the context is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Trigger the fetchMyMemberships method from our provider to load the data.
      ref.read(customerDashboardProvider.notifier).fetchMyMemberships();
    });
  }

  // A helper function to handle pull-to-refresh.
  Future<void> _refreshMemberships() async {
    await ref.read(customerDashboardProvider.notifier).fetchMyMemberships();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider to get the current state and rebuild the UI when it changes.
    final state = ref.watch(customerDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Memberships'),
      ),
      // Use RefreshIndicator to allow the user to pull down to refresh the list.
      body: RefreshIndicator(
        onRefresh: _refreshMemberships,
        child: _buildBody(state),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to the Mess Discovery screen to find new messes.
        },
        label: const Text('Find a Mess'),
        icon: const Icon(Icons.search),
      ),
    );
  }

  // Helper method to build the body based on the current state.
  Widget _buildBody(CustomerDashboardState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state.error != null) {
      return Center(child: Text('An error occurred: ${state.error}'));
    } else if (state.memberships.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'You have not joined any messes yet. Tap the "Find a Mess" button to get started!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    } else {
      // If data is available, display it in a list using our custom card.
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
}
