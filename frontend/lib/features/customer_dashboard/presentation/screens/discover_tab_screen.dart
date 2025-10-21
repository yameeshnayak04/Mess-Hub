// lib/features/customer_dashboard/presentation/screens/discover_tab_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

// You'll need to integrate with your existing mess discovery feature
// Import your existing mess provider
// import 'package:mess_management_system/features/mess_discovery/presentation/providers/mess_provider.dart';

class DiscoverTabScreen extends ConsumerStatefulWidget {
  const DiscoverTabScreen({super.key});

  @override
  ConsumerState<DiscoverTabScreen> createState() => _DiscoverTabScreenState();
}

class _DiscoverTabScreenState extends ConsumerState<DiscoverTabScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _isLoadingLocation = false;
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    setState(() => _isLoadingLocation = true);

    final status = await Permission.location.request();
    if (status.isGranted) {
      await _getCurrentLocation();
    }

    setState(() => _isLoadingLocation = false);
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search messes...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      setState(() => _showMap = !_showMap);
                    },
                    icon: Icon(_showMap ? Icons.list : Icons.map),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _showMap ? _buildMapView() : _buildListView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    if (_isLoadingLocation) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentLocation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Location not available'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _requestLocationPermission,
              child: const Text('Enable Location'),
            ),
          ],
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentLocation!,
        initialZoom: 14.0,
        onTap: (_, __) {}, // Handle map tap
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.mess_management_system',
        ),

        // Current location marker
        MarkerLayer(
          markers: [
            Marker(
              point: _currentLocation!,
              width: 80,
              height: 80,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'You',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Add mess markers here from your mess provider
            // Example:
            // ...nearbyMesses.map((mess) => Marker(...))
          ],
        ),
      ],
    );
  }

  Widget _buildListView() {
    // Use your existing mess list implementation
    // This is a placeholder
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5, // Replace with actual mess count
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.restaurant),
            ),
            title: Text('Mess Name $index'),
            subtitle: const Text('Address • 2.5 km away'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    SizedBox(width: 4),
                    Text('4.5'),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('₹3000/mo'),
              ],
            ),
            onTap: () {
              // Navigate to mess detail screen
            },
          ),
        );
      },
    );
  }
}
