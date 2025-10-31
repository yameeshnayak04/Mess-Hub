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
    _tabController =
        TabController(length: 3, vsync: this); // Initialize TabController
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
          // Rating and Review Count / Distance
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                mess.averageRating != null && mess.averageRating! > 0
                    ? mess.averageRating!.toStringAsFixed(1)
                    : 'No Rating',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                '(${mess.reviewCount ?? 0} reviews)',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
              const Spacer(), // Pushes distance to the right
              if (mess.distance !=
                  null) // Show distance if available (from discover)
                Text(
                  '${(mess.distance! / 1000).toStringAsFixed(1)} km away',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryOrange,
                        fontWeight: FontWeight.w500,
                      ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Address
          _buildInfoRow(context, Icons.location_on_outlined,
              '${mess.address}, ${mess.city}'),
          const SizedBox(height: 12),

          // Chips: Cuisine, Service Type, Tiffin
          Wrap(spacing: 8, runSpacing: 4, children: [
            _buildChip(mess.cuisine),
            _buildChip(mess.serviceType),
            // Show Tiffin chip conditionally
            if (mess.tiffinService)
              _buildChip('Tiffin Available', AppTheme.successGreen),
          ]),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Basic Thali Details Section
          _buildSectionTitle(context, 'Basic Thali Includes'),
          const SizedBox(height: 8),
          _buildInfoRow(
              context,
              Icons.restaurant_menu_outlined,
              mess.basicThaliDetails.isNotEmpty
                  ? mess.basicThaliDetails
                  : 'Not specified'),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Timings Section
          _buildSectionTitle(context, 'Timings'),
          const SizedBox(height: 8),
          _buildInfoRow(context, Icons.wb_sunny_outlined,
              'Lunch: ${mess.timings.lunch.start} - ${mess.timings.lunch.end}'),
          const SizedBox(height: 8),
          _buildInfoRow(context, Icons.nightlight_outlined,
              'Dinner: ${mess.timings.dinner.start} - ${mess.timings.dinner.end}'),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Plans Section
          _buildSectionTitle(context, 'Monthly Plans'),
          const SizedBox(height: 8),
          if (mess.plans.isEmpty)
            Padding(
              // Add padding for empty state
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: const Text('No monthly plans listed.',
                  style: TextStyle(color: AppTheme.textSecondary)),
            )
          else
            // Use Column for non-scrollable list within SingleChildScrollView
            Column(
              children: mess.plans
                  .map((plan) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Text(plan.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium)), // Allow name to wrap
                            const SizedBox(width: 16),
                            Text('₹${plan.rate.toStringAsFixed(0)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          // Daily Rate (Show only if applicable)
          if (mess.dailyThaliRate != null &&
              mess.serviceType == 'Both Daily & Monthly') ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Daily Thali Rate',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontStyle: FontStyle.italic)),
                Text('₹${mess.dailyThaliRate!.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Rules Section
          _buildSectionTitle(context, 'Rules & Policies'),
          const SizedBox(height: 8),
          _buildInfoRow(context, Icons.calendar_month_outlined,
              'Min. Leave for Rebate: ${mess.rules.minLeaveDaysForRebate} days'),
          const SizedBox(height: 8),
          _buildInfoRow(context, Icons.money_off_csred_outlined,
              'Rebate per Meal (on leave): ₹${mess.rules.rebatePerThali.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _buildInfoRow(context, Icons.skip_next_outlined,
              'Skip Allowance: ${mess.rules.skipAllowancePercent.toStringAsFixed(0)}% meals/month'),
          // Conditionally display optional rules
          if (mess.rules.securityDeposit != null &&
              mess.rules.securityDeposit! > 0) ...[
            const SizedBox(height: 8),
            _buildInfoRow(context, Icons.shield_outlined,
                'Security Deposit: ₹${mess.rules.securityDeposit!.toStringAsFixed(0)}'),
          ],
          if (mess.rules.minMonthlyCharge != null &&
              mess.rules.minMonthlyCharge! > 0) ...[
            const SizedBox(height: 8),
            _buildInfoRow(context, Icons.receipt_long_outlined,
                'Min. Monthly Charge: ₹${mess.rules.minMonthlyCharge!.toStringAsFixed(0)}'),
          ],
          // Add padding below rules before the next section or end
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Helper for info rows with icons
  Widget _buildInfoRow(BuildContext context, IconData icon, String text,
      {Color? iconColor}) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start, // Align text nicely if it wraps
      children: [
        Padding(
          // Add padding around icon for better spacing
          padding: const EdgeInsets.only(top: 2.0),
          child:
              Icon(icon, size: 18, color: iconColor ?? AppTheme.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }

  // Helper for section titles
  Widget _buildSectionTitle(BuildContext context, String title) {
    // Use headlineSmall for better hierarchy
    return Text(title, style: Theme.of(context).textTheme.headlineSmall);
  }

  // Chip widget
  Widget _buildChip(String label, [Color? color]) {
    final chipColor = color ?? AppTheme.primaryOrange;
    // Use Flutter's Chip widget for consistency and semantics
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(
          color: chipColor, fontSize: 12, fontWeight: FontWeight.w500),
      backgroundColor: chipColor.withOpacity(0.1),
      visualDensity: VisualDensity.compact, // Make chip smaller
      side: BorderSide(color: chipColor.withOpacity(0.3)),
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 2), // Adjust padding
    );
  }

  // Placeholder for Menu Tab
  Widget _buildMenuTab(Mess mess) {
    // TODO: Implement menu fetching and display
    return const Center(child: Text('Menu Tab Content (To be implemented)'));
  }

  // *** CORRECTED _buildReviewsTab ***
  Widget _buildReviewsTab(Mess mess) {
    // Watch the reviews part of the state *within* this tab builder
    final reviewsAsyncValue =
        ref.watch(messDetailsProvider(widget.messId).select((s) => s.reviews));
    // Return the actual reviews section widget, passing the AsyncValue
    // Use SingleChildScrollView as the direct child for scrolling.
    // REMOVED RefreshIndicator - the top-level one handles refresh.
    return SingleChildScrollView(
        child: _buildReviewsSection(context, reviewsAsyncValue));
  }

  // Builds the Reviews Section content
  Widget _buildReviewsSection(
      BuildContext context, AsyncValue<List<Review>> reviewsAsyncValue) {
    // Add horizontal padding for consistency
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // No need for a title here if it's within a tab
          // _buildSectionTitle(context, 'Reviews'),
          // const SizedBox(height: 12),
          reviewsAsyncValue.when(
            data: (reviews) {
              if (reviews.isEmpty) {
                return const Center(
                    child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48.0), // More padding
                  child: Column(
                    // Use column for icon + text
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review_outlined,
                          size: 60, color: AppTheme.textSecondary),
                      SizedBox(height: 16),
                      Text('No reviews yet. Be the first!',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                ));
              }
              // Use ListView.builder for potentially long lists
              return ListView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(), // Important within SingleChildScrollView
                itemCount: reviews.length, // Show all fetched reviews for now
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppTheme.lightOrange,
                                child: Text(
                                  (review.userName?.isNotEmpty ?? false)
                                      ? review.userName![0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: AppTheme.primaryOrange,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  review.userName ?? 'Anonymous',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              // Display rating stars
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                    5,
                                    (i) => Icon(
                                          i < review.rating
                                              ? Icons.star_rounded
                                              : Icons.star_border_rounded,
                                          color: Colors.amber,
                                          size: 18,
                                        )),
                              ),
                            ],
                          ),
                          // Display comment only if present and not empty
                          if (review.comment != null &&
                              review.comment!.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(review.comment!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppTheme.textSecondary)),
                          ],
                          const SizedBox(height: 8), // Spacing before date
                          Text(
                            // Format date nicely (e.g., Oct 29, 2025, 5:15 PM)
                            DateFormat.yMMMd().add_jm().format(review.createdAt
                                    ?.toLocal() ??
                                DateTime
                                    .now()), // Convert to local time if needed
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: AppTheme.textSecondary
                                        .withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                // No separator needed as cards have margin
              );
            },
            loading: () => const Center(
                child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48.0),
              child: CircularProgressIndicator(),
            )),
            error: (error, stack) => Center(
                child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48.0),
              child: Text('Could not load reviews: $error',
                  style: const TextStyle(color: AppTheme.errorRed)),
            )),
          ),
          // TODO: Add "View All Reviews" button if limiting initial display
          // TODO: Add "Write a Review" button
          const SizedBox(height: 24), // Padding at the end
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
