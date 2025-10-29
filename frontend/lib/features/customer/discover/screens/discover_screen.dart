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
import '../../../../core/utils/constants.dart'; // Import constants

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});
  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String? _selectedCuisine;
  String? _selectedServiceType;
  bool _isMapView = false;
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  // Helper to construct full URL (moved from previous example)
  String fullImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return ''; // Let error builder handle
    }
    if (path.startsWith('http')) {
      return path; // Already a full URL
    }
    // Prepend base URL
    return ApiConstants.baseUrl + path;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
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

  @override
  Widget build(BuildContext context) {
    final messesState = ref.watch(discoverProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Messes'),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            onPressed: () => setState(() => _isMapView = !_isMapView),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search messes...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppTheme.surfaceColor,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: AppTheme.surfaceColor,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCuisine,
                    decoration: const InputDecoration(
                      labelText: 'Cuisine',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(value: 'Veg', child: Text('Veg')),
                      DropdownMenuItem(
                          value: 'Non-Veg', child: Text('Non-Veg')),
                      DropdownMenuItem(value: 'Both', child: Text('Both')),
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
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedServiceType,
                    decoration: const InputDecoration(
                      labelText: 'Service Type',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(
                          value: 'Monthly Only', child: Text('Monthly Only')),
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
              ],
            ),
          ),

          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(discoverProvider.notifier).refresh(),
              child: messesState.when(
                data: (messes) {
                  if (messes.isEmpty) return _buildEmptyState(context);
                  // *** MAP FIX: Wrap in Column/Flexible ***
                  if (_isMapView) {
                    return Column(
                      children: [
                        Flexible(
                          child: _buildMapView(context, messes),
                        ),
                      ],
                    );
                  } else {
                    return _buildListView(context, messes);
                  }
                },
                loading: () => const LoadingAnimation(
                    message: 'Finding messes near you...'),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: AppTheme.errorRed),
                        const SizedBox(height: 16),
                        Text('Failed to load messes',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(error.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () =>
                              ref.read(discoverProvider.notifier).refresh(),
                          child: const Text('Retry'),
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

  Widget _buildEmptyState(BuildContext context) {
    // ... (no changes)
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off,
                size: 80, color: AppTheme.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('No Messes Found',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or check back later',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
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
      child: InkWell(
        onTap: () => context.go('/mess-details/${mess.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mess.messImage != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                // *** IMAGE FIX: Use fullImageUrl helper ***
                child: Image.network(
                  fullImageUrl(mess.messImage),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholderImage(),
                ),
              )
            else
              _buildPlaceholderImage(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          mess.messName,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (mess.averageRating != null &&
                          mess.averageRating! > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber[700],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.star,
                                size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              mess.averageRating!.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ]),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
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
                      if (mess.distance != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${(mess.distance! / 1000).toStringAsFixed(1)} km',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primaryOrange,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _buildChip(mess.cuisine),
                    _buildChip(mess.serviceType),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    // ... (no changes)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: AppTheme.lightOrange, borderRadius: BorderRadius.circular(16)),
      child: Text(label,
          style: const TextStyle(
              color: AppTheme.primaryOrange,
              fontSize: 12,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildPlaceholderImage() {
    // ... (no changes)
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
          color: AppTheme.primaryOrange.withOpacity(0.1),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
      child:
          const Icon(Icons.restaurant, size: 64, color: AppTheme.primaryOrange),
    );
  }

  Widget _buildMapView(BuildContext context, List<Mess> messes) {
    // ... (no changes)
    final markers = <Marker>[];
    LatLng? first;
    for (final m in messes) {
      final latLng = _extractLatLng(m);
      if (latLng == null) continue;
      first ??= latLng;
      markers.add(
        Marker(
          point: latLng,
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () => _showMessSheet(context, m),
            child: const Icon(Icons.location_pin,
                size: 44, color: AppTheme.primaryOrange),
          ),
        ),
      );
    }
    final center = first ??
        LatLng(messes.first.location.coordinates[1],
            messes.first.location.coordinates[0]);

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 12,
        interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName:
              'dev.naitikjain.mess_management', // Use your package name
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  LatLng? _extractLatLng(Mess m) {
    // This is correct, uses the Location model
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.lightOrange,
                    backgroundImage: (mess.messImage != null)
                        ? NetworkImage(fullImageUrl(mess.messImage))
                        : null,
                    child: (mess.messImage == null)
                        ? const Icon(Icons.restaurant,
                            color: AppTheme.primaryOrange)
                        : null,
                  ),
                  title: Text(mess.messName,
                      style: Theme.of(context).textTheme.titleMedium),
                  subtitle: Text('${mess.address}, ${mess.city}',
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: (mess.distance != null)
                      ? Text('${(mess.distance! / 1000).toStringAsFixed(1)} km',
                          style: const TextStyle(
                              color: AppTheme.primaryOrange,
                              fontWeight: FontWeight.w600))
                      : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _pill(mess.cuisine),
                    const SizedBox(width: 8),
                    _pill(mess.serviceType),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.go('/mess-details/${mess.id}'),
                        child: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: AppTheme.lightOrange, borderRadius: BorderRadius.circular(14)),
      child: Text(label,
          style: const TextStyle(
              color: AppTheme.primaryOrange, fontWeight: FontWeight.w500)),
    );
  }
}
