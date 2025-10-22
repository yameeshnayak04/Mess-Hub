// lib/features/mess_discovery/presentation/screens/mess_list_screen.dart
// Reworked to use flutter_map (OSM), forward geocoding, and current-location.
// Keep file path the same so existing routes still work.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:mess_management_system/core/routing/app_router.dart';
import 'package:mess_management_system/features/mess_discovery/presentation/providers/mess_provider.dart';
import 'package:mess_management_system/features/mess_discovery/presentation/widgets/mess_card_widget.dart';

class MessListScreen extends ConsumerStatefulWidget {
  const MessListScreen({super.key});
  @override
  ConsumerState<MessListScreen> createState() => _MessListScreenState();
}

class _MessListScreenState extends ConsumerState<MessListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(24.6443, 77.3187); // India centroid
  bool _mapReady = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _determinePositionAndFetchMesses();
  }

  Future<void> _determinePositionAndFetchMesses() async {
    try {
      setState(() => _locating = true);
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions permanently denied.');
      }

      final pos = await Geolocator.getCurrentPosition();
      final here = LatLng(pos.latitude, pos.longitude);
      _center = here;
      await ref.read(messDiscoveryProvider.notifier).fetchNearbyMesses(
            lat: here.latitude, lng: here.longitude, radius: 50, // city-wide
          );
      if (mounted) {
        _moveMap(here, 13);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$e\nShowing a default area.'),
              backgroundColor: Colors.orange),
        );
      }
      await ref.read(messDiscoveryProvider.notifier).fetchNearbyMesses(
            lat: _center.latitude,
            lng: _center.longitude,
            radius: 50,
          );
      if (mounted) _moveMap(_center, 6.5);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _moveMap(LatLng c, double z) {
    _mapController.move(c, z);
    setState(() => _mapReady = true);
  }

  Future<void> _searchAddress() async {
    final q = _searchController.text.trim();
    ref.read(messDiscoveryProvider.notifier).searchMesses(q);
    if (q.isEmpty) return;
    try {
      final results = await locationFromAddress(q);
      if (results.isNotEmpty) {
        final l = results.first;
        final here = LatLng(l.latitude, l.longitude);
        _center = here;
        _moveMap(here, 14);
        // Optionally widen or narrow radius fetch depending on zoom.
        await ref.read(messDiscoveryProvider.notifier).fetchNearbyMesses(
              lat: here.latitude,
              lng: here.longitude,
              radius: 10,
            );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Place not found, try a more specific query.'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messDiscoveryProvider);
    final notifier = ref.read(messDiscoveryProvider.notifier);

    final markers = state.filteredMesses
        .where((m) => m.location.coordinates.length == 2)
        .map((m) {
      final lng = (m.location.coordinates[0] as num).toDouble();
      final lat = (m.location.coordinates[1] as num).toDouble();
      return Marker(
        point: LatLng(lat, lng),
        width: 44,
        height: 44,
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(
            context,
            AppRouter.messDetailRoute,
            arguments: {'messId': m.id},
          ),
          child: const Icon(Icons.location_pin, color: Colors.red, size: 44),
        ),
      );
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Discover Messes'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.list_alt_rounded), text: 'List View'),
              Tab(icon: Icon(Icons.map_rounded), text: 'Map View'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, address, city',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            notifier.searchMesses('');
                          },
                        )
                      : null,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchAddress(),
                onChanged: notifier.searchMesses,
              ),
            ),
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildListView(state),
                  Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _center,
                          initialZoom: 12,
                          onMapReady: () => setState(() => _mapReady = true),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'com.example.mess_management_system',
                          ),
                          if (markers.isNotEmpty) MarkerLayer(markers: markers),
                        ],
                      ),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton.extended(
                          onPressed: _locating
                              ? null
                              : _determinePositionAndFetchMesses,
                          label:
                              Text(_locating ? 'Locating...' : 'My location'),
                          icon: const Icon(Icons.my_location),
                        ),
                      ),
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

  Widget _buildListView(MessDiscoveryState state) {
    if (state.isLoading && state.allMesses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(child: Text('An error occurred: ${state.error}'));
    }
    if (state.filteredMesses.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? 'No messes found nearby.'
              : 'No messes match your search.',
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _determinePositionAndFetchMesses,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: state.filteredMesses.length,
        itemBuilder: (context, index) {
          final mess = state.filteredMesses[index];
          return MessCardWidget(
            mess: mess,
            onTap: () => Navigator.pushNamed(
              context,
              AppRouter.messDetailRoute,
              arguments: {'messId': mess.id},
            ),
          );
        },
      ),
    );
  }
}
