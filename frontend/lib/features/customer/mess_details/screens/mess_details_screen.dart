import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_animation.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../models/mess.dart';
import '../providers/mess_details_provider.dart';

class MessDetailsScreen extends ConsumerStatefulWidget {
  final String messId;

  const MessDetailsScreen({
    super.key,
    required this.messId,
  });

  @override
  ConsumerState<MessDetailsScreen> createState() => _MessDetailsScreenState();
}

class _MessDetailsScreenState extends ConsumerState<MessDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedPlan;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _callManager(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  Future<void> _joinMess(Mess mess) async {
    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plan')),
      );
      return;
    }

    setState(() => _isJoining = true);

    try {
      final repository = ref.read(messDetailsRepositoryProvider);
      await repository.joinMess(widget.messId, _selectedPlan!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Membership request sent successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messDetailsState = ref.watch(messDetailsProvider(widget.messId));

    return messDetailsState.when(
      data: (mess) => Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    mess.messName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                  ),
                  background: mess.messImage != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              mess.messImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderImage();
                              },
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : _buildPlaceholderImage(),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.primaryOrange,
                    unselectedLabelColor: AppTheme.textSecondary,
                    indicatorColor: AppTheme.primaryOrange,
                    tabs: const [
                      Tab(text: 'Info'),
                      Tab(text: 'Menu'),
                      Tab(text: 'Reviews'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildInfoTab(mess),
              _buildMenuTab(mess),
              _buildReviewsTab(mess),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomBar(context, mess),
      ),
      loading: () => const Scaffold(
        body: LoadingAnimation(message: 'Loading mess details...'),
      ),
      error: (error, stack) => Scaffold(
        body: ErrorAnimation(message: 'Failed to load mess details'),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppTheme.primaryOrange.withOpacity(0.1),
      child: const Center(
        child: Icon(
          Icons.restaurant,
          size: 80,
          color: AppTheme.primaryOrange,
        ),
      ),
    );
  }

  Widget _buildInfoTab(Mess mess) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: AppTheme.primaryOrange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${mess.address}, ${mess.city}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.restaurant_menu,
                          color: AppTheme.primaryOrange),
                      const SizedBox(width: 8),
                      Text(
                        mess.cuisine,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppTheme.primaryOrange),
                      const SizedBox(width: 8),
                      Text(
                        mess.serviceType,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  if (mess.maxCapacity != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.people, color: AppTheme.primaryOrange),
                        const SizedBox(width: 8),
                        Text(
                          'Capacity: ${mess.maxCapacity} members',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: 'Call Manager',
                    onPressed: () => _callManager(mess.contactPhone),
                    icon: Icons.phone,
                    isOutlined: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Meal Timings
          Text(
            'Meal Timings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTimingRow(
                    'Lunch',
                    mess.timings.lunch.start,
                    mess.timings.lunch.end,
                  ),
                  const Divider(height: 24),
                  _buildTimingRow(
                    'Dinner',
                    mess.timings.dinner.start,
                    mess.timings.dinner.end,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Plans
          Text(
            'Available Plans',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...mess.plans.map((plan) => _buildPlanCard(plan)),

          if (mess.serviceType == 'Both Daily & Monthly' &&
              mess.dailyThaliRate != null) ...[
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Thali',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Walk-in rate per meal',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                    Text(
                      '₹${mess.dailyThaliRate!.toStringAsFixed(0)}',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppTheme.primaryOrange,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Rules
          Text(
            'Mess Rules',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRuleItem(
                    'Minimum leave days for rebate',
                    '${mess.rules.minLeaveDaysForRebate} days',
                  ),
                  const Divider(height: 24),
                  _buildRuleItem(
                    'Rebate per thali',
                    '₹${mess.rules.rebatePerThali.toStringAsFixed(0)}',
                  ),
                  const Divider(height: 24),
                  _buildRuleItem(
                    'Skip allowance',
                    '${mess.rules.skipAllowancePercent.toStringAsFixed(0)}%',
                  ),
                  if (mess.rules.securityDeposit != null) ...[
                    const Divider(height: 24),
                    _buildRuleItem(
                      'Security deposit',
                      '₹${mess.rules.securityDeposit!.toStringAsFixed(0)}',
                    ),
                  ],
                  if (mess.rules.minMonthlyCharge != null) ...[
                    const Divider(height: 24),
                    _buildRuleItem(
                      'Minimum monthly charge',
                      '₹${mess.rules.minMonthlyCharge!.toStringAsFixed(0)}',
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 80), // Extra padding for bottom bar
        ],
      ),
    );
  }

  Widget _buildTimingRow(String meal, String start, String end) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          meal,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          '$start - $end',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryOrange,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(MessPlan plan) {
    final isSelected = _selectedPlan == plan.name;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? AppTheme.lightOrange : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPlan = isSelected ? null : plan.name;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Radio<String>(
                value: plan.name,
                groupValue: _selectedPlan,
                onChanged: (value) {
                  setState(() => _selectedPlan = value);
                },
                activeColor: AppTheme.primaryOrange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  plan.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '₹${plan.rate.toStringAsFixed(0)}/month',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryOrange,
              ),
        ),
      ],
    );
  }

  Widget _buildMenuTab(Mess mess) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.restaurant_menu,
              size: 80,
              color: AppTheme.primaryOrange,
            ),
            const SizedBox(height: 16),
            Text(
              'Menu',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Weekly menu will be displayed here\nonce you join this mess',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsTab(Mess mess) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.rate_review_outlined,
              size: 80,
              color: AppTheme.primaryOrange,
            ),
            const SizedBox(height: 16),
            Text(
              'Reviews',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            if (mess.averageRating != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 32),
                  const SizedBox(width: 8),
                  Text(
                    mess.averageRating!.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${mess.reviewCount ?? 0} reviews',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ] else
              Text(
                'No reviews yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, Mess mess) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: PrimaryButton(
          text: 'Join This Mess',
          onPressed: _selectedPlan != null ? () => _joinMess(mess) : null,
          isLoading: _isJoining,
          icon: Icons.add_circle_outline,
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppTheme.surfaceColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
