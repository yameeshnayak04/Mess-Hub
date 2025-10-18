import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mess_management_system/features/mess_discovery/domain/entities/mess.dart';
import 'package:mess_management_system/features/mess_discovery/presentation/providers/mess_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messDiscoveryProvider.notifier).fetchMessDetails(widget.messId);
    });
  }

  // --- FULLY IMPLEMENTED JOIN MESS LOGIC ---
  void _onJoinMessPressed(Mess mess) {
    if (mess.mealPlans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('This mess is not offering any monthly plans right now.')));
      return;
    }
    // Show a bottom sheet for the user to select a meal plan.
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _MealPlanSelectionSheet(
        mess: mess,
        onPlanSelected: (planId) async {
          Navigator.of(ctx).pop(); // Close the bottom sheet
          try {
            await ref
                .read(messDiscoveryProvider.notifier)
                .joinMess(messId: mess.id, mealPlanId: planId);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Successfully joined mess!'),
                  backgroundColor: Colors.green));
              // Navigate back to the customer's main dashboard after joining.
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(e.toString()), backgroundColor: Colors.red));
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messDiscoveryProvider);
    return Scaffold(
      body: _buildBody(state, context),
      bottomNavigationBar: state.selectedMess != null
          ? _buildJoinButton(state.selectedMess!)
          : null,
    );
  }

  // The rest of the build methods are the same correct versions from before.
  // I am including them here again for completeness.

  Widget _buildBody(MessDiscoveryState state, BuildContext context) {
    if (state.isLoading && state.selectedMess == null)
      return const Center(child: CircularProgressIndicator());
    if (state.error != null)
      return Center(child: Text('An error occurred: ${state.error}'));
    if (state.selectedMess == null)
      return const Center(child: Text('Mess details could not be loaded.'));

    final mess = state.selectedMess!;
    final textTheme = Theme.of(context).textTheme;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220.0,
          pinned: true,
          stretch: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(mess.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 2, color: Colors.black54)])),
            background: Container(
                color: Colors.grey.shade400,
                child: const Center(
                    child: Icon(Icons.photo_library_outlined,
                        size: 80, color: Colors.white70))),
          ),
        ),
        SliverList(
            delegate: SliverChildListDelegate([
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(textTheme, 'Information'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.location_on_outlined, mess.address),
                    _buildInfoRow(Icons.phone_outlined, mess.managerContact),
                    const SizedBox(height: 16),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      Chip(
                          label: Text(mess.serviceType),
                          avatar: const Icon(Icons.business_center_outlined)),
                      Chip(
                          label: Text(mess.cuisine),
                          avatar: Icon(mess.cuisine == 'Veg'
                              ? Icons.eco_rounded
                              : Icons.fastfood_rounded)),
                      if (mess.reviewCount > 0)
                        Chip(
                            label: Text(
                                '${mess.averageRating.toStringAsFixed(1)} (${mess.reviewCount} reviews)'),
                            avatar: const Icon(Icons.star_rounded,
                                color: Colors.amber)),
                    ]),
                    const Divider(height: 32),
                    _buildSectionHeader(textTheme, 'Timings'),
                    if (mess.timings.lunchStart != null)
                      _buildInfoRow(Icons.wb_sunny_outlined,
                          'Lunch: ${mess.timings.lunchStart} - ${mess.timings.lunchEnd}'),
                    if (mess.timings.dinnerStart != null)
                      _buildInfoRow(Icons.nights_stay_outlined,
                          'Dinner: ${mess.timings.dinnerStart} - ${mess.timings.dinnerEnd}'),
                    const Divider(height: 32),
                    _buildSectionHeader(textTheme, 'Pricing & Plans'),
                    if (mess.dailyThaliRate != null && mess.dailyThaliRate! > 0)
                      _buildPricingCard(context,
                          icon: Icons.local_atm,
                          title: 'Daily Thali Rate',
                          value: '₹${mess.dailyThaliRate!.toStringAsFixed(0)}'),
                    const SizedBox(height: 16),
                    if (mess.mealPlans.isNotEmpty) ...[
                      Text('Monthly Plans',
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      ...mess.mealPlans
                          .map((plan) => _buildPlanTile(plan, context))
                    ] else
                      const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child:
                              Text('No monthly plans are currently offered.')),
                  ])),
        ])),
      ],
    );
  }

  Padding _buildSectionHeader(TextTheme textTheme, String title) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)));
  Widget _buildInfoRow(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 16),
        Expanded(
            child:
                Text(text, style: const TextStyle(fontSize: 16, height: 1.4)))
      ]));
  Widget _buildPricingCard(BuildContext context,
          {required IconData icon,
          required String title,
          required String value}) =>
      Card(
          elevation: 0,
          color:
              Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
          child: ListTile(
              leading: Icon(icon,
                  color: Theme.of(context).colorScheme.onSecondaryContainer),
              title: Text(title),
              trailing: Text(value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context)
                          .colorScheme
                          .onSecondaryContainer))));
  Widget _buildPlanTile(MealPlan plan, BuildContext context) => Card(
      elevation: 0,
      color: Colors.blueGrey.shade50,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
          title: Text(plan.name,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: Text('₹${plan.currentPrice.toStringAsFixed(0)} / month',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16))));

  Widget _buildJoinButton(Mess mess) {
    bool canJoin = mess.serviceType != 'Daily Only';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Join This Mess'),
        style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16)),
        onPressed: canJoin ? () => _onJoinMessPressed(mess) : null,
      ),
    );
  }
}

// A new private widget for the meal plan selection bottom sheet.
class _MealPlanSelectionSheet extends StatefulWidget {
  final Mess mess;
  final Function(String) onPlanSelected;
  const _MealPlanSelectionSheet(
      {required this.mess, required this.onPlanSelected});

  @override
  State<_MealPlanSelectionSheet> createState() =>
      __MealPlanSelectionSheetState();
}

class __MealPlanSelectionSheetState extends State<_MealPlanSelectionSheet> {
  String? _selectedPlanId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Select a Meal Plan',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...widget.mess.mealPlans.map((plan) {
              return RadioListTile<String>(
                title: Text(plan.name),
                subtitle:
                    Text('₹${plan.currentPrice.toStringAsFixed(0)} / month'),
                value: plan.id,
                groupValue: _selectedPlanId,
                onChanged: (value) => setState(() => _selectedPlanId = value),
              );
            }),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (_selectedPlanId == null || _isLoading)
                  ? null
                  : () {
                      setState(() => _isLoading = true);
                      widget.onPlanSelected(_selectedPlanId!);
                    },
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white))
                  : const Text('Confirm & Join'),
            ),
          ],
        ),
      ),
    );
  }
}
