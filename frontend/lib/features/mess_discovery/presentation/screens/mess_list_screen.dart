// lib/features/mess_discovery/presentation/screens/mess_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/core/routing/app_router.dart';
import 'package:mess_management_system/features/mess_discovery/presentation/providers/mess_provider.dart';
import 'package:mess_management_system/features/mess_discovery/presentation/widgets/mess_card_widget.dart';

// Use a ConsumerStatefulWidget to listen to providers and fetch data in initState.
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
    // Use WidgetsBinding to safely call the provider method after the first frame is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  // Helper function to fetch data, used for both initial load and refresh.
  Future<void> _fetchData() async {
    // For demonstration, we're using hardcoded coordinates for Indore, India.
    // In a real app, you would get the user's current location using a package
    // like 'geolocator' and pass the real lat/lng here.
    await ref
        .read(messDiscoveryProvider.notifier)
        .fetchNearbyMesses(lat: 22.7196, lng: 75.8577);
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider to get the current state and rebuild the UI when it changes.
    final state = ref.watch(messDiscoveryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Nearby Messes'),
        actions: [
          // A button to filter results.
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onPressed: () {
              // TODO: Implement filter functionality in a bottom sheet.
            },
          ),
        ],
      ),
      // Use RefreshIndicator to allow the user to pull down to refresh the list.
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: _buildBody(state),
      ),
    );
  }

  // Helper method to build the body of the screen based on the current state.
  Widget _buildBody(MessDiscoveryState state) {
    // If the data is loading for the first time, show a centered spinner.
    if (state.isLoading && state.messes.isEmpty) {
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
    // If the list of messes is empty, show a helpful prompt.
    else if (state.messes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No messes found nearby.\nTry expanding your search radius.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }
    // If data is available, display it in a list using our custom MessCardWidget.
    else {
      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: state.messes.length,
        itemBuilder: (context, index) {
          final mess = state.messes[index];
          return MessCardWidget(
            mess: mess,
            onTap: () {
              // When a card is tapped, navigate to the MessDetailScreen,
              // passing the unique mess ID as an argument.
              Navigator.pushNamed(
                context,
                AppRouter.messDetailRoute,
                arguments: {'messId': mess.id},
              );
            },
          );
        },
      );
    }
  }
}
