// lib/features/mess_discovery/presentation/screens/mess_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/mess_discovery/presentation/providers/mess_provider.dart';
import 'package:mess_management_system/features/mess_discovery/domain/entities/mess.dart';

class MessDetailScreen extends ConsumerStatefulWidget {
  final String messId;

  const MessDetailScreen({super.key, required this.messId});

  @override
  ConsumerState<MessDetailScreen> createState() => _MessDetailScreenState();
}

class _MessDetailScreenState extends ConsumerState<MessDetailScreen> {
  @override
  void initState() {
    super.initState();
    // As soon as the screen loads, call the provider to fetch the details for this specific mess.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messDiscoveryProvider.notifier).fetchMessDetails(widget.messId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider to get the current state.
    final state = ref.watch(messDiscoveryProvider);
    return Scaffold(
      appBar: AppBar(
        title: state.selectedMess != null
            ? Text(state.selectedMess!.name)
            : const Text('Loading...'),
      ),
      body: _buildBody(state, context),
      // A bottom bar with a prominent "Join Mess" button.
      bottomNavigationBar: state.selectedMess != null
          ? _buildJoinButton(state.selectedMess!)
          : null,
    );
  }

  Widget _buildBody(MessDiscoveryState state, BuildContext context) {
    if (state.isLoading && state.selectedMess == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(child: Text('An error occurred: ${state.error}'));
    }
    if (state.selectedMess == null) {
      return const Center(child: Text('Mess details could not be loaded.'));
    }

    // If we have the data, display the full profile.
    final mess = state.selectedMess!;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Gallery Placeholder
          Container(
            height: 200,
            color: Colors.grey.shade300,
            child: const Center(
                child: Icon(Icons.photo_camera, size: 50, color: Colors.grey)),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mess.name,
                    style: textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.location_on_outlined, mess.address),
                _buildInfoRow(Icons.phone_outlined, mess.managerContact),
                _buildInfoRow(Icons.watch_later_outlined,
                    'Lunch: ${mess.timings.lunchStart} - ${mess.timings.lunchEnd}'),
                _buildInfoRow(Icons.watch_later_outlined,
                    'Dinner: ${mess.timings.dinnerStart} - ${mess.timings.dinnerEnd}'),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text('Monthly Plans',
                    style: textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (mess.mealPlans.isNotEmpty)
                  ...mess.mealPlans.map((plan) => _buildPlanTile(plan, context))
                else
                  const Text('No monthly plans available.'),

                // TODO: Add Reviews Section here
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildPlanTile(MealPlan plan, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(plan.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          '₹${plan.currentPrice.toStringAsFixed(0)} / month',
          style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildJoinButton(Mess mess) {
    // Handle the case where the mess is full.
    bool canJoin =
        mess.serviceType != 'Daily Only'; // Simplified capacity check

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: canJoin
            ? () {
                // TODO: Implement the join mess functionality by calling a provider method.
                // This would likely show a bottom sheet to select a meal plan before confirming.
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Joining ${mess.name}...')));
              }
            : null, // The button is disabled if `onPressed` is null.
        child: Text(
            canJoin ? 'Join This Mess' : 'Currently Not Accepting Members'),
      ),
    );
  }
}
