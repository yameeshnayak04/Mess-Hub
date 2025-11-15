// lib/features/manager/create_mess/widgets/location_picker_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_theme.dart';

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

class _LocationPickerMapState extends State<LocationPickerMap>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng? _currentCenter;
  LatLng? _selectedMarker;
  bool _isLoadingLocation = true;
  bool _isMovingToLocation = false;
  double _currentZoom = 15.0;

  late AnimationController _markerAnimationController;
  late Animation<double> _markerScaleAnimation;
  late Animation<double> _markerBounceAnimation;

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialLocation;
    _selectedMarker = widget.initialLocation;

    // Setup marker animation
    _markerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _markerScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _markerAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _markerBounceAnimation = Tween<double>(begin: -20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _markerAnimationController,
        curve: Curves.bounceOut,
      ),
    );

    _determineInitialPosition();
  }

  @override
  void dispose() {
    _markerAnimationController.dispose();
    super.dispose();
  }

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
        positionToUse = const LatLng(24.6469, 77.3188); // Fallback to Bhopal
        if (mounted) {
          _showCustomSnackBar(
            'Using default location. Please select your location manually.',
            isError: true,
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
        _mapController.move(positionToUse, _currentZoom);
        _markerAnimationController.forward();
      } catch (_) {}
    });

    widget.onLocationSelected(positionToUse);
  }

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

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _moveToCurrentLocation() async {
    setState(() => _isMovingToLocation = true);

    try {
      final pos = await _getCurrentLocationData();
      final current = LatLng(pos.latitude, pos.longitude);

      if (!mounted) return;

      setState(() => _selectedMarker = current);
      _mapController.move(current, 15.0);
      _markerAnimationController.reset();
      _markerAnimationController.forward();

      widget.onLocationSelected(current);

      _showCustomSnackBar('Location updated successfully', isError: false);
    } catch (e) {
      if (mounted) {
        _showCustomSnackBar(
          'Could not get current location',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isMovingToLocation = false);
      }
    }
  }

  void _showCustomSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppTheme.errorRed : AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onMapTap(TapPosition tapPosition, LatLng latLng) {
    setState(() => _selectedMarker = latLng);
    _markerAnimationController.reset();
    _markerAnimationController.forward();
    widget.onLocationSelected(latLng);
  }

  void _zoomIn() {
    final newZoom = (_currentZoom + 1).clamp(1.0, 18.0);
    setState(() => _currentZoom = newZoom);
    _mapController.move(_mapController.camera.center, newZoom);
  }

  void _zoomOut() {
    final newZoom = (_currentZoom - 1).clamp(1.0, 18.0);
    setState(() => _currentZoom = newZoom);
    _mapController.move(_mapController.camera.center, newZoom);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLocation && _currentCenter == null) {
      return _buildLoadingState();
    }

    final mapCenter = _currentCenter ?? const LatLng(24.6469, 77.3188);

    return Stack(
      children: [
        // Map Layer
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapCenter,
              initialZoom: _currentZoom,
              onTap: _onMapTap,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() => _currentZoom = position.zoom ?? _currentZoom);
                }
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              minZoom: 5.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mess_management_system',
                subdomains: const ['a', 'b', 'c'],
              ),

              // Animated Marker Layer
              if (_selectedMarker != null)
                AnimatedBuilder(
                  animation: _markerAnimationController,
                  builder: (context, child) {
                    return MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedMarker!,
                          width: 50,
                          height: 60,
                          alignment: Alignment.topCenter,
                          child: Transform.scale(
                            scale: _markerScaleAnimation.value,
                            child: Transform.translate(
                              offset: Offset(0, _markerBounceAnimation.value),
                              child: _buildCustomMarker(),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),

        // Gradient Overlay for Better Contrast
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Top Info Card
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: _buildInfoCard(),
        ),

        // Zoom Controls
        Positioned(
          right: 16,
          top: 100,
          child: _buildZoomControls(),
        ),

        // Current Location Button
        Positioned(
          bottom: 16,
          right: 16,
          child: _buildLocationButton(),
        ),

        // Coordinate Display
        if (_selectedMarker != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 90,
            child: _buildCoordinateCard(),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryOrange.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                color: AppTheme.primaryOrange,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Loading Map...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we fetch your location',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.touch_app,
              color: AppTheme.primaryOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tap on Map',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Select your mess location',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomControls() {
    return Column(
      children: [
        _buildZoomButton(
          icon: Icons.add,
          onPressed: _zoomIn,
        ),
        const SizedBox(height: 8),
        _buildZoomButton(
          icon: Icons.remove,
          onPressed: _zoomOut,
        ),
      ],
    );
  }

  Widget _buildZoomButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.borderColor.withOpacity(0.2),
            ),
          ),
          child: Icon(
            icon,
            color: AppTheme.textPrimary,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationButton() {
    return Material(
      color: _isMovingToLocation
          ? AppTheme.primaryOrange.withOpacity(0.9)
          : AppTheme.primaryOrange,
      borderRadius: BorderRadius.circular(16),
      elevation: 6,
      shadowColor: AppTheme.primaryOrange.withOpacity(0.4),
      child: InkWell(
        onTap: _isMovingToLocation ? null : _moveToCurrentLocation,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: _isMovingToLocation
                ? null
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryOrange,
                      Color(0xFFFF8C42),
                    ],
                  ),
          ),
          child: _isMovingToLocation
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 26,
                ),
        ),
      ),
    );
  }

  Widget _buildCoordinateCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.place,
              color: AppTheme.successGreen,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Location',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_selectedMarker!.latitude.toStringAsFixed(5)}, ${_selectedMarker!.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomMarker() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.errorRed,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.errorRed.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on,
              color: AppTheme.errorRed,
              size: 20,
            ),
          ),
        ),
        Container(
          width: 2,
          height: 10,
          decoration: BoxDecoration(
            color: AppTheme.errorRed,
            boxShadow: [
              BoxShadow(
                color: AppTheme.errorRed.withOpacity(0.3),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.errorRed.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
