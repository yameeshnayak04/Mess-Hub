// lib/features/discover/screens/discover_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/loading_animation.dart';
import '../../../../models/mess.dart';
import '../providers/discover_provider.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});
  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedCuisine;
  String? _selectedServiceType;
  bool _isMapView = false;
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  late AnimationController _viewSwitchController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _viewSwitchController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _viewSwitchController, curve: Curves.easeInOut),
    );
    _viewSwitchController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen<AsyncValue<List<Mess>>>(discoverProvider, (prev, next) {
        next.whenOrNull(error: (e, st) {
          final msg = e.toString();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text(msg)),
                  ],
                ),
                backgroundColor: AppTheme.errorRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        });
      });
    });
  }

  String fullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return ApiConstants.baseUrl + path;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _viewSwitchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(discoverProvider.notifier).loadMesses(
            cuisine: _selectedCuisine,
            serviceType: _selectedServiceType,
            search: text.trim().isEmpty ? null : text.trim(),
          );
    });
  }

  void _toggleView() {
    setState(() => _isMapView = !_isMapView);
    _viewSwitchController.reset();
    _viewSwitchController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final messesState = ref.watch(discoverProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.primaryOrange,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryOrange,
                      AppTheme.primaryOrange.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.restaurant_menu_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Discover',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Text(
                                    'Find your perfect mess',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _isMapView
                                      ? Icons.view_list_rounded
                                      : Icons.map_rounded,
                                  color: AppTheme.primaryOrange,
                                ),
                                onPressed: _toggleView,
                                tooltip: _isMapView ? 'List View' : 'Map View',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search by name, location...',
                    hintStyle: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.6),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.primaryOrange,
                      size: 24,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: AppTheme.textSecondary,
                            ),
                            onPressed: () {
                              _searchCtrl.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Filters
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCuisine,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: AppTheme.primaryOrange),
                          hint: Row(
                            children: [
                              const Icon(Icons.restaurant_rounded,
                                  size: 18, color: AppTheme.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                'Cuisine',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: null, child: Text('All Cuisines')),
                            DropdownMenuItem(
                                value: 'Veg', child: Text('Vegetarian')),
                            DropdownMenuItem(
                                value: 'Non-Veg', child: Text('Non-Veg')),
                            DropdownMenuItem(
                                value: 'Both', child: Text('Both')),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedCuisine = value);
                            ref.read(discoverProvider.notifier).loadMesses(
                                  cuisine: value,
                                  serviceType: _selectedServiceType,
                                  search: _searchCtrl.text.trim().isEmpty
                                      ? null
                                      : _searchCtrl.text.trim(),
                                );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedServiceType,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: AppTheme.primaryOrange),
                          hint: Row(
                            children: [
                              const Icon(Icons.room_service_rounded,
                                  size: 18, color: AppTheme.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                'Service',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: null, child: Text('All Services')),
                            DropdownMenuItem(
                                value: 'Monthly Only',
                                child: Text('Monthly Only')),
                            DropdownMenuItem(
                                value: 'Both Daily & Monthly',
                                child: Text('Daily & Monthly')),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedServiceType = value);
                            ref.read(discoverProvider.notifier).loadMesses(
                                  cuisine: _selectedCuisine,
                                  serviceType: value,
                                  search: _searchCtrl.text.trim().isEmpty
                                      ? null
                                      : _searchCtrl.text.trim(),
                                );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Active Filters Badge
          if (_selectedCuisine != null || _selectedServiceType != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Active Filters:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(width: 8),
                    if (_selectedCuisine != null) ...[
                      _buildFilterChip(
                        _selectedCuisine!,
                        () {
                          setState(() => _selectedCuisine = null);
                          ref.read(discoverProvider.notifier).loadMesses(
                                cuisine: null,
                                serviceType: _selectedServiceType,
                                search: _searchCtrl.text.trim().isEmpty
                                    ? null
                                    : _searchCtrl.text.trim(),
                              );
                        },
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (_selectedServiceType != null) ...[
                      _buildFilterChip(
                        _selectedServiceType == 'Monthly Only'
                            ? 'Monthly'
                            : 'Daily & Monthly',
                        () {
                          setState(() => _selectedServiceType = null);
                          ref.read(discoverProvider.notifier).loadMesses(
                                cuisine: _selectedCuisine,
                                serviceType: null,
                                search: _searchCtrl.text.trim().isEmpty
                                    ? null
                                    : _searchCtrl.text.trim(),
                              );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Content
          SliverFillRemaining(
            child: RefreshIndicator(
              color: AppTheme.primaryOrange,
              onRefresh: () => ref.read(discoverProvider.notifier).refresh(),
              child: messesState.when(
                data: (messes) {
                  if (messes.isEmpty) return _buildEmptyState(context);
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: _isMapView
                        ? _buildMapView(context, messes)
                        : _buildListView(context, messes),
                  );
                },
                loading: () => const LoadingAnimation(
                    message: 'Finding messes near you...'),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.error_outline_rounded,
                              size: 64, color: AppTheme.errorRed),
                        ),
                        const SizedBox(height: 24),
                        Text('Failed to load messes',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(error.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () =>
                              ref.read(discoverProvider.notifier).refresh(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.primaryOrange,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              color: AppTheme.primaryOrange,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_rounded,
                  size: 80, color: AppTheme.textSecondary.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            Text('No Messes Found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search criteria',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_selectedCuisine != null || _selectedServiceType != null)
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedCuisine = null;
                    _selectedServiceType = null;
                  });
                  ref.read(discoverProvider.notifier).loadMesses();
                },
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Clear All Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryOrange,
                  side: const BorderSide(color: AppTheme.primaryOrange),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context, List<Mess> messes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messes.length,
      itemBuilder: (context, index) => _buildMessCard(context, messes[index]),
    );
  }

  Widget _buildMessCard(BuildContext context, Mess mess) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => context.push('/mess-details/${mess.id}'),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with overlay badges
            Stack(
              children: [
                if (mess.messImage != null)
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.network(
                      fullImageUrl(mess.messImage),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderImage(),
                    ),
                  )
                else
                  _buildPlaceholderImage(),

                // Rating badge
                if (mess.averageRating != null && mess.averageRating! > 0)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber[700],
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            mess.averageRating!.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Distance badge
                if (mess.distance != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me_rounded,
                              size: 14, color: AppTheme.primaryOrange),
                          const SizedBox(width: 4),
                          Text(
                            '${(mess.distance! / 1000).toStringAsFixed(1)} km',
                            style: const TextStyle(
                              color: AppTheme.primaryOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mess.messName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${mess.address}, ${mess.city}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildChip(mess.cuisine, Icons.restaurant_rounded),
                      const SizedBox(width: 8),
                      _buildChip(mess.serviceType, Icons.room_service_rounded),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          Icon(icon, size: 14, color: AppTheme.primaryOrange),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.primaryOrange,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryOrange.withOpacity(0.2),
            AppTheme.primaryOrange.withOpacity(0.1),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: const Icon(Icons.restaurant_rounded,
          size: 64, color: AppTheme.primaryOrange),
    );
  }

  Widget _buildMapView(BuildContext context, List<Mess> messes) {
    final markers = <Marker>[];
    LatLng? first;
    for (final m in messes) {
      final latLng = _extractLatLng(m);
      if (latLng == null) continue;
      first ??= latLng;
      markers.add(
        Marker(
          point: latLng,
          width: 32, // Reduced from 50
          height: 32, // Reduced from 50
          child: GestureDetector(
            onTap: () => _showMessSheet(context, m),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryOrange.withOpacity(0.4),
                    blurRadius: 6, // Reduced from 8
                    spreadRadius: 1, // Reduced from 2
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on_rounded, // Changed to location icon
                size: 20, // Reduced from 28
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }
    final center = first ??
        LatLng(messes.first.location.coordinates[1],
            messes.first.location.coordinates[0]);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: 12,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'dev.yameesh_nayak.mess_hub',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }

  LatLng? _extractLatLng(Mess m) {
    try {
      if (m.location.coordinates.length == 2) {
        return LatLng(m.location.coordinates[1], m.location.coordinates[0]);
      }
    } catch (_) {}
    return null;
  }

  void _showMessSheet(BuildContext context, Mess mess) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryOrange.withOpacity(0.2),
                              AppTheme.primaryOrange.withOpacity(0.1),
                            ],
                          ),
                          image: mess.messImage != null
                              ? DecorationImage(
                                  image: NetworkImage(
                                      fullImageUrl(mess.messImage)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: mess.messImage == null
                            ? const Icon(
                                Icons.restaurant_rounded,
                                color: AppTheme.primaryOrange,
                                size: 32,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mess.messName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${mess.address}, ${mess.city}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (mess.distance != null)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.near_me_rounded,
                                  color: AppTheme.primaryOrange,
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(mess.distance! / 1000).toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                    color: AppTheme.primaryOrange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (mess.distance != null) const SizedBox(width: 12),
                      if (mess.averageRating != null && mess.averageRating! > 0)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  mess.averageRating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _pill(mess.cuisine, Icons.restaurant_rounded),
                      const SizedBox(width: 8),
                      _pill(mess.serviceType, Icons.room_service_rounded),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/mess-details/${mess.id}');
                      },
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('View Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _pill(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          Icon(icon, size: 14, color: AppTheme.primaryOrange),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.primaryOrange,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
