import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mess_management_system/core/routing/app_router.dart';
import 'package:mess_management_system/features/mess_discovery/presentation/providers/mess_provider.dart';
import 'package:mess_management_system/features/mess_discovery/presentation/widgets/mess_card_widget.dart';

class MessListScreen extends ConsumerStatefulWidget {
  const MessListScreen({super.key});

  @override
  ConsumerState<MessListScreen> createState() => _MessListScreenState();
}

class _MessListScreenState extends ConsumerState<MessListScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _searchController = TextEditingController();
  static const CameraPosition _kDefaultLocation = CameraPosition(
      target: LatLng(24.6443, 77.3187), zoom: 12.0); // Zoomed out a bit

  @override
  void initState() {
    super.initState();
    // Add a listener to the search controller to rebuild the UI when text changes,
    // which helps the suffix icon (clear button) appear/disappear instantly.
    _searchController.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _determinePositionAndFetchMesses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _determinePositionAndFetchMesses() async {
    // This function now has more robust error handling and clearer feedback.
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permissions are permanently denied, please enable them in settings.');
      }

      Position position = await Geolocator.getCurrentPosition();

      // Fetch messes within a large radius around the user.
      await _fetchMesses(
          lat: position.latitude,
          lng: position.longitude,
          animateMap: true,
          radius: 50);
    } catch (e) {
      _fetchForDefaultLocation(e.toString());
    }
  }

  // A unified function for fetching data to reduce code duplication.
  Future<void> _fetchMesses(
      {required double lat,
      required double lng,
      required double radius,
      bool animateMap = false}) async {
    final notifier = ref.read(messDiscoveryProvider.notifier);
    // Fetch messes within a 50km radius to get all messes "in the city".
    await notifier.fetchNearbyMesses(lat: lat, lng: lng, radius: radius);

    if (animateMap && mounted) {
      final GoogleMapController controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: 12.0)));
    }
  }

  void _fetchForDefaultLocation(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("$message Showing results for a default location.")));
    }
    _fetchMesses(
        lat: _kDefaultLocation.target.latitude,
        lng: _kDefaultLocation.target.longitude,
        radius: 50);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messDiscoveryProvider);
    final notifier = ref.read(messDiscoveryProvider.notifier);

    // This logic is now safer. It checks for valid coordinates before creating a marker.
    final Set<Marker> markers = state.filteredMesses.where((mess) {
      // Safety check: ensure coordinates are valid.
      return mess.location.coordinates.length == 2;
    }).map((mess) {
      return Marker(
        markerId: MarkerId(mess.id),
        position: LatLng(mess.location.coordinates[1],
            mess.location.coordinates[0]), // Map uses (lat, lng)
        infoWindow: InfoWindow(
            title: mess.name,
            snippet: mess.address,
            onTap: () => Navigator.pushNamed(context, AppRouter.messDetailRoute,
                arguments: {'messId': mess.id})),
      );
    }).toSet();

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
                  hintText: 'Search by name or address',
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
                onChanged: notifier.searchMesses,
              ),
            ),
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildListView(state),
                  GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: _kDefaultLocation,
                    onMapCreated: (GoogleMapController controller) {
                      if (!_mapController.isCompleted) {
                        _mapController.complete(controller);
                      }
                    },
                    markers: markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
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
          child: Text(_searchController.text.isEmpty
              ? 'No messes found nearby. Ensure you have created some in the database.'
              : 'No messes match your search.'));
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
            onTap: () => Navigator.pushNamed(context, AppRouter.messDetailRoute,
                arguments: {'messId': mess.id}),
          );
        },
      ),
    );
  }
}
