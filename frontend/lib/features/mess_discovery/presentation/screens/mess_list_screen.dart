// This file contains the UI for displaying a list of nearby messes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/mess_discovery/presentation/providers/mess_provider.dart';
import 'package:mess_management_system/features/mess_discovery/presentation/widgets/mess_card_widget.dart';

// Use ConsumerStatefulWidget to listen to providers and manage local state.
class MessListScreen extends ConsumerStatefulWidget {
  const MessListScreen({super.key});

  @override
  ConsumerState<MessListScreen> createState() => _MessListScreenState();
}

class _MessListScreenState extends ConsumerState<MessListScreen> {
  // This is called once when the widget is first created.
  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to call the provider method after the first frame is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // For demonstration, we're using hardcoded coordinates for Indore, India.
      // In a real app, you would get the user's current location using a package like 'geolocator'.
      ref
          .read(messDiscoveryProvider.notifier)
          .fetchNearbyMesses(22.7196, 75.8577);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider to get the current state and rebuild the UI when it changes.
    final state = ref.watch(messDiscoveryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Messes'),
        actions: [
          // A refresh button to re-fetch the data.
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref
                  .read(messDiscoveryProvider.notifier)
                  .fetchNearbyMesses(22.7196, 75.8577);
            },
          ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  // Helper method to build the body based on the current state.
  Widget _buildBody(MessDiscoveryState state) {
    if (state.isLoading) {
      // Show a loading spinner while data is being fetched.
      return const Center(child: CircularProgressIndicator());
    } else if (state.error != null) {
      // Show an error message if something went wrong.
      return Center(
        child: Text('An error occurred: ${state.error}'),
      );
    } else if (state.messes.isEmpty) {
      // Show a message if no messes are found.
      return const Center(
        child: Text('No messes found nearby.'),
      );
    } else {
      // If data is available, display it in a list.
      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: state.messes.length,
        itemBuilder: (context, index) {
          final mess = state.messes[index];
          return MessCardWidget(
            mess: mess,
            onTap: () {
              // TODO: Navigate to MessDetailScreen
              print('Tapped on mess: ${mess.name}');
            },
          );
        },
      );
    }
  }
}
