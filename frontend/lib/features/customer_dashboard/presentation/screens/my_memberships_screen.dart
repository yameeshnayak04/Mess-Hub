// This screen is the main dashboard for a logged-in customer, showing all their memberships.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/core/routing/app_router.dart';
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
    // This ensures that the context is available and prevents errors.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Trigger the fetchMyMemberships method from our provider to load the initial data.
      ref.read(customerDashboardProvider.notifier).fetchMyMemberships();
    });
  }

  // A helper function to handle the pull-to-refresh action.
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
        actions: [
          // A logout button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              // TODO: Implement logout functionality in auth_provider
              // This would clear SharedPreferences and navigate to the login screen.
            },
          ),
        ],
      ),
      // Use RefreshIndicator to allow the user to pull down to refresh the list.
      body: RefreshIndicator(
        onRefresh: _refreshMemberships,
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

  // Helper method to build the body of the screen based on the current state.
  Widget _buildBody(CustomerDashboardState state) {
    // If the data is loading for the first time, show a centered spinner.
    if (state.isLoading && state.memberships.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    // If an error occurred, show an informative message.
    else if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'An error occurred: ${state.error}\n\nPull down to try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }
    // If the user has no memberships, show a helpful prompt.
    else if (state.memberships.isEmpty) {
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
    }
    // If data is available, display it in a list using our custom MembershipCard widget.
    else {
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
