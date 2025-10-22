// lib/features/customer_dashboard/presentation/screens/discover_tab_screen.dart

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

class DiscoverTabScreen extends ConsumerStatefulWidget {
  const DiscoverTabScreen({super.key});

  @override
  ConsumerState<DiscoverTabScreen> createState() => _DiscoverTabScreenState();
}

class _DiscoverTabScreenState extends ConsumerState<DiscoverTabScreen> {
  // UI
  final TextEditingController _search = TextEditingController();
  bool _showMap = false;

  // Map
  final MapController _map = MapController();
  bool _mapReady = false;
  LatLng _center = const LatLng(23.2599, 77.4126); // fallback center (India)
  LatLng? _queuedCenter;
  double? _queuedZoom;

  // Debounce
  Timer? _debounce;

  // Lifecycle
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _ensureLocationAndFetch();
  }

  Future<void> _ensureLocationAndFetch() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) throw Exception('Location services are disabled.');
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied)
          throw Exception('Location permission denied.');
      }
      if (perm == LocationPermission.deniedForever) {
        throw Exception(
            'Location permission permanently denied in system settings.');
      }

      final pos = await Geolocator.getCurrentPosition();
      _center = LatLng(pos.latitude, pos.longitude);

      await ref.read(messDiscoveryProvider.notifier).fetchNearbyMesses(
            lat: _center.latitude,
            lng: _center.longitude,
            radius: 50,
          );

      _moveMapSafe(_center, 13.0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('$e\nShowing a default area.'),
            backgroundColor: Colors.orange),
      );
      await ref.read(messDiscoveryProvider.notifier).fetchNearbyMesses(
            lat: _center.latitude,
            lng: _center.longitude,
            radius: 50,
          );
      _moveMapSafe(_center, 6.5);
    }
  }

  void _moveMapSafe(LatLng c, double z) {
    if (_mapReady) {
      _map.move(c, z);
    } else {
      _queuedCenter = c;
      _queuedZoom = z;
    }
  }

  Future<void> _onSearch(String query) async {
    ref.read(messDiscoveryProvider.notifier).searchMesses(query);
    if (query.trim().isEmpty) return;

    // Try geocode query to move map and refetch in a smaller radius
    try {
      final results = await locationFromAddress(query);
      if (results.isNotEmpty) {
        final l = results.first;
        final here = LatLng(l.latitude, l.longitude);
        _center = here;
        _moveMapSafe(here, 14.0);
        await ref.read(messDiscoveryProvider.notifier).fetchNearbyMesses(
              lat: here.latitude,
              lng: here.longitude,
              radius: 10,
            );
      }
    } catch (_) {
      // Ignore geocoding errors; list filtering still applies
    }
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _onSearch(v));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messDiscoveryProvider);
    final notifier = ref.read(messDiscoveryProvider.notifier);

    // Build markers from live data
    final markers = state.filteredMesses.map((m) {
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

    final searchField = TextField(
      controller: _search,
      decoration: InputDecoration(
        hintText: 'Search by name, address, city',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: (_search.text.isNotEmpty)
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _search.clear();
                  notifier.searchMesses('');
                  setState(() {});
                },
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: _onSearch,
      onChanged: (v) {
        setState(() {}); // refresh suffix icon
        _onChanged(v);
      },
    );

    final list = state.isLoading && state.filteredMesses.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : state.error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load nearby messes.\n${state.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: state.filteredMesses.length,
                itemBuilder: (context, i) {
                  final mess = state.filteredMesses[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MessCardWidget(
                      mess: mess,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRouter.messDetailRoute,
                        arguments: {'messId': mess.id},
                      ),
                    ),
                  );
                },
              );

    final map = FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: 12,
        onMapReady: () {
          _mapReady = true;
          if (_queuedCenter != null) {
            _map.move(_queuedCenter!, _queuedZoom ?? 13);
            _queuedCenter = null;
            _queuedZoom = null;
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.mess_management_system',
        ),
        if (markers.isNotEmpty) MarkerLayer(markers: markers),
        // Current location marker
        MarkerLayer(
          markers: [
            Marker(
              point: _center,
              width: 36,
              height: 36,
              child:
                  const Icon(Icons.my_location, color: Colors.blue, size: 26),
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => setState(() => _showMap = !_showMap),
                    icon: Icon(_showMap ? Icons.list : Icons.map),
                    tooltip: _showMap ? 'Show list' : 'Show map',
                  ),
                ],
              ),
            ),
            Expanded(child: _showMap ? map : list),
          ],
        ),
      ),
    );
  }
}
