// lib/features/customer/mess_details/screens/mess_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import 'package:intl/intl.dart'; // For formatting rating and dates

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/loading_animation.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../models/mess.dart';
import '../../../../models/review.dart'; // Import Review model
import '../providers/mess_details_provider.dart';

class MessDetailsScreen extends ConsumerStatefulWidget {
  final String messId;
  const MessDetailsScreen({super.key, required this.messId});

  @override
  ConsumerState<MessDetailsScreen> createState() => _MessDetailsScreenState();
}

// *** Need TabController for TabBar ***
class _MessDetailsScreenState extends ConsumerState<MessDetailsScreen>
    with SingleTickerProviderStateMixin {
  // Add mixin
  String? _selectedPlan; // State to hold the chosen plan for joining
  late TabController _tabController; // Declare TabController

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // One-off error snackbars
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen(messDetailsProvider(widget.messId), (prev, next) {
        final errors = <Object?>[];
        next.mess.whenOrNull(error: (e, _) => errors.add(e));
        next.menu.whenOrNull(error: (e, _) => errors.add(e));
        next.reviews.whenOrNull(error: (e, _) => errors.add(e));
        if (errors.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errors.first.toString())),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose TabController
    super.dispose();
  }

  // Helper to construct full URL (can be moved to a utils file)
  String fullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return ApiConstants.baseUrl + path;
  }

  // Function to launch phone dialer
  Future<void> _callManager(String phoneNumber) async {
    // Remove non-digit characters just in case
    final String cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanPhoneNumber,
    );
    try {
      if (!await launchUrl(launchUri)) {
        throw 'Could not launch $launchUri';
      }
    } catch (e) {
      print('Error launching dialer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open dialer for $phoneNumber')),
        );
      }
    }
  }

  // Show dialog to select plan before joining
  void _showPlanSelectionDialog(BuildContext context, Mess mess) {
    // Reset selection when dialog opens
    _selectedPlan = null;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use StatefulBuilder to manage the dialog's internal state for selection
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select a Plan to Join'),
              contentPadding:
                  const EdgeInsets.only(top: 20.0), // Adjust padding
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  // Handle case where plans might be empty
                  children: mess.plans.isEmpty
                      ? [
                          const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text("No monthly plans available."))
                        ]
                      : mess.plans.map((plan) {
                          return RadioListTile<String>(
                            title: Text(plan.name),
                            subtitle: Text(
                                '₹${plan.rate.toStringAsFixed(0)} / month'),
                            value: plan.name,
                            groupValue: _selectedPlan,
                            onChanged: (String? value) {
                              setDialogState(() {
                                // Update dialog state
                                _selectedPlan = value;
                              });
                            },
                            activeColor: AppTheme.primaryOrange,
                          );
                        }).toList(),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    _selectedPlan = null; // Reset selection
                    Navigator.of(dialogContext).pop();
                  },
                ),
                Consumer(// Use Consumer to access loading state inside actions
                    builder: (context, ref, child) {
                  // Read provider state directly for loading
                  final isJoining =
                      ref.watch(messDetailsProvider(widget.messId)).isJoining;
                  return PrimaryButton(
                    text: 'Confirm Join',
                    isLoading: isJoining,
                    // Disable button if no plan selected or already joining
                    onPressed: (_selectedPlan == null || isJoining)
                        ? null
                        : () {
                            if (_selectedPlan != null) {
                              Navigator.of(dialogContext)
                                  .pop(); // Close dialog FIRST
                              _handleJoinMess(
                                  _selectedPlan!); // Call join function
                            }
                          },
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  // Handle join mess API call and feedback
  Future<void> _handleJoinMess(String planName) async {
    final notifier = ref.read(messDetailsProvider(widget.messId).notifier);
    final success = await notifier.joinMess(planName);

    if (!mounted) return; // Check if widget is still in tree

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Join request sent successfully! Waiting for manager approval.'),
          backgroundColor: AppTheme.successGreen,
          duration: Duration(seconds: 3),
        ),
      );
      // Optional: Navigate away or refresh state if needed
      // context.pop(); // Go back? Or maybe refresh membership list elsewhere
      // ref.invalidate(myMembershipsProvider); // Example invalidation
    } else {
      // Read the specific join error message from the provider state
      final error = ref.read(messDetailsProvider(widget.messId)).joinError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join mess: ${error ?? 'Unknown error'}'),
          backgroundColor: AppTheme.errorRed,
          duration: Duration(seconds: 3),
        ),
      );
    }
    // No need to reset _selectedPlan here, dialog resets it
  }

  // *** CORRECTED build method ***
  @override
  Widget build(BuildContext context) {
    // Watch the provider state
    final state = ref.watch(messDetailsProvider(widget.messId));
    // Get the AsyncValue<Mess> from the state
    final messAsyncValue = state.mess;

    // Use .when on the AsyncValue<Mess> to handle states
    return messAsyncValue.when(
      data: (mess) => Scaffold(
        // Build scaffold only when data is available
        body: RefreshIndicator(
          // Added RefreshIndicator
          onRefresh: () async =>
              ref.read(messDetailsProvider(widget.messId).notifier).refresh(),
          child: NestedScrollView(
            // Use NestedScrollView for collapsing AppBar + Tabs
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 250,
                  pinned: true,
                  floating: false, // Keep false for typical behavior
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding:
                        const EdgeInsetsDirectional.only(start: 72, bottom: 16),
                    title: Text(
                      mess.messName, // Use data from 'mess' variable
                      style: const TextStyle(
                          fontSize: 16, // Smaller title when collapsed
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3,
                                color: Colors.black45)
                          ]),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    background: mess.messImage != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                fullImageUrl(
                                    mess.messImage), // Use helper and data
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildPlaceholderImage();
                                },
                              ),
                              // Gradient overlay for title visibility
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7)
                                      ],
                                      stops: const [
                                        0.5,
                                        1.0
                                      ] // Adjust gradient position
                                      ),
                                ),
                              ),
                            ],
                          )
                        : _buildPlaceholderImage(),
                  ),
                ),
                // Pinned TabBar below the AppBar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    // Use helper delegate
                    TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primaryOrange,
                      unselectedLabelColor: AppTheme.textSecondary,
                      indicatorColor: AppTheme.primaryOrange,
                      tabs: const [
                        Tab(text: 'Info'),
                        Tab(text: 'Menu'), // Placeholder for Menu Tab
                        Tab(text: 'Reviews'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            // Body content is the TabBarView
            body: TabBarView(
              controller: _tabController,
              children: [
                // Pass the 'mess' data to the tab builders
                _buildInfoTab(mess),
                _buildMenuTab(mess), // Placeholder for Menu Tab content
                _buildReviewsTab(
                    mess), // Pass mess for context, reviews come from provider
              ],
            ),
          ),
        ),
        // Pass 'mess' data to the bottom bar builder
        bottomNavigationBar: _buildBottomBar(context, mess),
      ),
      // Loading state: Show a simple Scaffold with LoadingAnimation
      loading: () => const Scaffold(
        body: LoadingAnimation(message: 'Loading mess details...'),
      ),
      // Error state: Show a simple Scaffold with Error content and retry
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')), // Add AppBar for context
        body: Center(
            child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: AppTheme.errorRed),
              const SizedBox(height: 16),
              Text(
                'Failed to load mess details',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(error.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                // Refresh data on retry
                onPressed: () => ref
                    .read(messDetailsProvider(widget.messId).notifier)
                    .refresh(),
                child: const Text('Retry'),
              )
            ],
          ),
        )),
      ),
    );
  }

  // Placeholder image widget
  Widget _buildPlaceholderImage() {
    return Container(
      color: AppTheme.primaryOrange.withOpacity(0.1),
      child: const Center(
          child: Icon(Icons.image_not_supported_outlined,
              size: 64, color: AppTheme.primaryOrange)),
    );
  }

  // Builds the Info Tab content
  Widget _buildInfoTab(Mess mess) {
    // Use SingleChildScrollView for potentially long content
    return SingleChildScrollView(child: _buildMessContent(context, mess));
  }

  // Builds the main content area for the Info Tab
  Widget _buildMessContent(BuildContext context, Mess mess) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating and Review Count Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mess.averageRating != null && mess.averageRating! > 0
                              ? mess.averageRating!.toStringAsFixed(1)
                              : 'No Rating',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        Text(
                          '${mess.reviewCount ?? 0} reviews',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (mess.distance != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryOrange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppTheme.primaryOrange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(mess.distance! / 1000).toStringAsFixed(1)} km',
                            style: const TextStyle(
                              color: AppTheme.primaryOrange,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Address Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: AppTheme.primaryOrange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '${mess.address}, ${mess.city}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Chips: Cuisine, Service Type, Tiffin
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip(mess.cuisine, AppTheme.primaryOrange),
              _buildChip(mess.serviceType, Colors.blue),
              if (mess.tiffinService)
                _buildChip('Tiffin Available', AppTheme.successGreen),
            ],
          ),
          const SizedBox(height: 24),

          // Basic Thali Details Section
          _buildSectionCard(
            context,
            icon: Icons.restaurant_menu_outlined,
            title: 'Basic Thali Includes',
            content: mess.basicThaliDetails.isNotEmpty
                ? mess.basicThaliDetails
                : 'Not specified',
          ),
          const SizedBox(height: 16),

          // Timings Section
          _buildSectionCard(
            context,
            icon: Icons.access_time_outlined,
            title: 'Timings',
            content: Column(
              children: [
                _buildTimingRow(
                  context,
                  Icons.wb_sunny_outlined,
                  'Lunch',
                  '${mess.timings.lunch.start} - ${mess.timings.lunch.end}',
                  Colors.orange,
                ),
                const SizedBox(height: 12),
                _buildTimingRow(
                  context,
                  Icons.nightlight_outlined,
                  'Dinner',
                  '${mess.timings.dinner.start} - ${mess.timings.dinner.end}',
                  Colors.indigo,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Plans Section
          _buildSectionCard(
            context,
            icon: Icons.payment_outlined,
            title: 'Monthly Plans',
            content: mess.plans.isEmpty
                ? const Text(
                    'No monthly plans listed.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  )
                : Column(
                    children: [
                      ...mess.plans.map((plan) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryOrange.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.primaryOrange.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    plan.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryOrange,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '₹${plan.rate.toStringAsFixed(0)}/mo',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      if (mess.dailyThaliRate != null &&
                          mess.serviceType == 'Both Daily & Monthly')
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Daily Thali Rate',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '₹${mess.dailyThaliRate!.toStringAsFixed(0)}/day',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),

          // Rules Section
          _buildSectionCard(
            context,
            icon: Icons.rule_outlined,
            title: 'Rules & Policies',
            content: Column(
              children: [
                _buildRuleItem(
                  context,
                  Icons.calendar_month_outlined,
                  'Min. Leave for Rebate',
                  '${mess.rules.minLeaveDaysForRebate} days',
                ),
                const Divider(height: 20),
                _buildRuleItem(
                  context,
                  Icons.money_off_csred_outlined,
                  'Rebate per Meal',
                  '₹${mess.rules.rebatePerThali.toStringAsFixed(0)}',
                ),
                const Divider(height: 20),
                _buildRuleItem(
                  context,
                  Icons.skip_next_outlined,
                  'Skip Allowance',
                  '${mess.rules.skipAllowancePercent.toStringAsFixed(0)}% meals/month',
                ),
                if (mess.rules.securityDeposit != null &&
                    mess.rules.securityDeposit! > 0) ...[
                  const Divider(height: 20),
                  _buildRuleItem(
                    context,
                    Icons.shield_outlined,
                    'Security Deposit',
                    '₹${mess.rules.securityDeposit!.toStringAsFixed(0)}',
                  ),
                ],
                if (mess.rules.minMonthlyCharge != null &&
                    mess.rules.minMonthlyCharge! > 0) ...[
                  const Divider(height: 20),
                  _buildRuleItem(
                    context,
                    Icons.receipt_long_outlined,
                    'Min. Monthly Charge',
                    '₹${mess.rules.minMonthlyCharge!.toStringAsFixed(0)}',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Helper for section cards
  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required dynamic content,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: AppTheme.primaryOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (content is String)
              Text(
                content,
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              content,
          ],
        ),
      ),
    );
  }

  // Helper for timing rows
  Widget _buildTimingRow(
    BuildContext context,
    IconData icon,
    String label,
    String time,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper for rule items
  Widget _buildRuleItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryOrange,
              ),
        ),
      ],
    );
  }

  // Chip widget - updated for better visuals
  Widget _buildChip(String label, [Color? color]) {
    final chipColor = color ?? AppTheme.primaryOrange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: chipColor.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: chipColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Menu Tab with better design
  Widget _buildMenuTab(Mess mess) {
    final menuAsync =
        ref.watch(messDetailsProvider(widget.messId).select((s) => s.menu));
    return menuAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.primaryOrange),
              ),
              SizedBox(height: 16),
              Text(
                'Loading menu...',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  size: 48,
                  color: AppTheme.errorRed,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Could not load menu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                style: const TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      data: (menus) {
        if (menus.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.restaurant_menu_rounded,
                      size: 64,
                      color: AppTheme.textSecondary.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Menus Scheduled',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The mess hasn\'t added any upcoming menus yet',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: menus.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final m = menus[index];
            final date = DateTime.tryParse(m['date']?.toString() ?? '');
            final lunch =
                (m['lunchItems'] as List?)?.cast<String>() ?? const <String>[];
            final dinner =
                (m['dinnerItems'] as List?)?.cast<String>() ?? const <String>[];

            final isToday = date != null &&
                date.year == DateTime.now().year &&
                date.month == DateTime.now().month &&
                date.day == DateTime.now().day;

            final isTomorrow = date != null &&
                date.year == DateTime.now().add(const Duration(days: 1)).year &&
                date.month ==
                    DateTime.now().add(const Duration(days: 1)).month &&
                date.day == DateTime.now().add(const Duration(days: 1)).day;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isToday
                      ? AppTheme.primaryOrange.withOpacity(0.3)
                      : Colors.grey.shade200,
                  width: isToday ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppTheme.primaryOrange.withOpacity(0.1)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 20,
                            color: isToday
                                ? AppTheme.primaryOrange
                                : AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                date != null
                                    ? DateFormat('EEEE').format(date.toLocal())
                                    : 'Scheduled',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                date != null
                                    ? DateFormat('MMM d, y')
                                        .format(date.toLocal())
                                    : 'Menu',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (isToday)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryOrange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Today',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else if (isTomorrow)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Tomorrow',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Lunch Section
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.wb_sunny_rounded,
                                  size: 16,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Lunch',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (lunch.isEmpty)
                            Text(
                              'No items listed',
                              style: TextStyle(
                                color: AppTheme.textSecondary.withOpacity(0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: lunch.map((item) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.orange.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade600,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        item,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.orange.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Dinner Section
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.indigo.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.nightlight_rounded,
                                  size: 16,
                                  color: Colors.indigo.shade700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Dinner',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.indigo.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (dinner.isEmpty)
                            Text(
                              'No items listed',
                              style: TextStyle(
                                color: AppTheme.textSecondary.withOpacity(0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: dinner.map((item) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.indigo.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: Colors.indigo.shade600,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        item,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.indigo.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Enhanced Reviews Tab with better design
  Widget _buildReviewsTab(Mess mess) {
    final reviewsAsyncValue =
        ref.watch(messDetailsProvider(widget.messId).select((s) => s.reviews));
    return SingleChildScrollView(
      child: _buildReviewsSection(context, reviewsAsyncValue),
    );
  }

  Widget _buildReviewsSection(
      BuildContext context, AsyncValue<List<Review>> reviewsAsyncValue) {
    final notifier = ref.read(messDetailsProvider(widget.messId).notifier);
    final state = ref.watch(messDetailsProvider(widget.messId));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          reviewsAsyncValue.when(
            data: (reviews) {
              if (reviews.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 64.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.rate_review_rounded,
                            size: 64,
                            color: AppTheme.textSecondary.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No Reviews Yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to share your experience!',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  // Reviews header with count
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryOrange.withOpacity(0.1),
                          AppTheme.primaryOrange.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryOrange.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.reviews_rounded,
                            color: AppTheme.primaryOrange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${reviews.length} ${reviews.length == 1 ? 'Review' : 'Reviews'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'From our customers',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Reviews list
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reviews.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      final initial = (review.userName?.isNotEmpty ?? false)
                          ? review.userName![0].toUpperCase()
                          : '?';

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User info and rating
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.primaryOrange,
                                          AppTheme.primaryOrange
                                              .withOpacity(0.7),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        initial,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          review.userName ?? 'Anonymous',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          DateFormat.yMMMd().format(
                                              review.createdAt?.toLocal() ??
                                                  DateTime.now()),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppTheme.textSecondary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.amber.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${review.rating}.0',
                                          style: const TextStyle(
                                            color: Colors.amber,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Star rating display
                              const SizedBox(height: 12),
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < review.rating
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    color: i < review.rating
                                        ? Colors.amber
                                        : Colors.grey.shade300,
                                    size: 20,
                                  ),
                                ),
                              ),

                              // Review comment
                              if (review.comment != null &&
                                  review.comment!.trim().isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    review.comment!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.textPrimary,
                                          height: 1.5,
                                        ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Load more button
                  if (state.reviewsHasMore)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Center(
                        child: OutlinedButton.icon(
                          onPressed: () => notifier.loadMoreReviews(),
                          icon: const Icon(Icons.expand_more_rounded),
                          label: const Text('Load More Reviews'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryOrange,
                            side:
                                const BorderSide(color: AppTheme.primaryOrange),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation(AppTheme.primaryOrange),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading reviews...',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppTheme.errorRed,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Could not load reviews',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Bottom bar for actions
  Widget _buildBottomBar(BuildContext context, Mess mess) {
    // Watch the joining state from the provider
    final isJoining = ref
        .watch(messDetailsProvider(widget.messId).select((s) => s.isJoining));
    return Container(
      // Add padding for safe area automatically with SafeArea widget
      padding: const EdgeInsets.fromLTRB(
          16, 12, 16, 12), // Remove bottom padding here
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        // Use SafeArea to handle notches/bottom bars
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.call_outlined, size: 20),
                label: const Text('Call Manager'),
                onPressed: () =>
                    _callManager(mess.contactPhone), // Call the function
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14), // Consistent padding
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.w600) // Match button style
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                text: 'Join Mess',
                icon: Icons.add_circle_outline,
                isLoading: isJoining, // Show loading state
                // Disable button while joining
                onPressed: isJoining
                    ? null
                    : () => _showPlanSelectionDialog(context, mess),
              ),
            ),
          ],
        ),
      ),
    );
  }
} // End of _MessDetailsScreenState

// Helper class for sticky TabBar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Wrap TabBar in a background color matching the Scaffold or AppBar theme
    return Container(
      color: Theme.of(context).colorScheme.surface, // Use theme surface color
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    // Rebuild if the TabBar itself changes (unlikely here, but good practice)
    return tabBar != oldDelegate.tabBar;
  }
}
