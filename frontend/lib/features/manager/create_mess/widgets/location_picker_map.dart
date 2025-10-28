// lib/features/manager/create_mess/widgets/location_picker_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_theme.dart';

// Removed flutter_map_dragmarker import
class LocationPickerMap extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng) onLocationSelected;
  const LocationPickerMap({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  final MapController _mapController = MapController();
  LatLng? _currentCenter;
  LatLng? _selectedMarker;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialLocation;
    _selectedMarker = widget.initialLocation;
    _determineInitialPosition();
  }

  // ADD explicit return type
  Future<void> _determineInitialPosition() async {
    setState(() => _isLoadingLocation = true);
    LatLng positionToUse;
    if (widget.initialLocation != null) {
      positionToUse = widget.initialLocation!;
    } else {
      try {
        final pos = await _getCurrentLocationData();
        positionToUse = LatLng(pos.latitude, pos.longitude);
      } catch (e) {
        positionToUse = const LatLng(24.6469, 77.3188); // Fallback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Could not get current location. Using default. Error: $e')),
          );
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _currentCenter = positionToUse;
      _isLoadingLocation = false;
      _selectedMarker ??= positionToUse;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _mapController.move(positionToUse, 15.0);
      } catch (_) {}
    });
    widget.onLocationSelected(positionToUse);
  }

  // ADD explicit return type
  Future<Position> _getCurrentLocationData() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }
    return Geolocator.getCurrentPosition();
  }

  // ADD explicit return type
  Future<void> _moveToCurrentLocation() async {
    try {
      final pos = await _getCurrentLocationData();
      final current = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _selectedMarker = current);
      _mapController.move(current, 15.0);
      widget.onLocationSelected(current);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get current location: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLocation && _currentCenter == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final mapCenter = _currentCenter ?? const LatLng(24.6469, 77.3188);
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: mapCenter,
            initialZoom: 15.0,
            onTap: (_, latLng) {
              setState(() => _selectedMarker = latLng);
              widget.onLocationSelected(latLng);
            },
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.mess_management_system',
            ),
            if (_selectedMarker != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedMarker!,
                    width: 40,
                    height: 40,
                    alignment: Alignment.topCenter,
                    child: const Icon(Icons.location_pin,
                        size: 40, color: AppTheme.errorRed),
                  ),
                ],
              ),
          ],
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            mini: true,
            heroTag: null,
            onPressed: _moveToCurrentLocation,
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}
