import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/navigation_provider.dart';
import '../../models/building_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/colors.dart';
import 'widgets/turn_by_turn_widget.dart';
import 'widgets/custom_navigation_controls.dart';
import 'indoor_navigation_screen.dart';

class OutdoorNavigationScreen extends StatefulWidget {
  final BuildingModel? targetBuilding;
  final EntryPoint? targetEntryPoint;
  final String? destinationId;
  final String? destinationName;
  final double? destLat;
  final double? destLng;

  const OutdoorNavigationScreen({
    super.key,
    this.targetBuilding,
    this.targetEntryPoint,
    this.destinationId,
    this.destinationName,
    this.destLat,
    this.destLng,
  });

  @override
  State<OutdoorNavigationScreen> createState() =>
      _OutdoorNavigationScreenState();
}

class _OutdoorNavigationScreenState extends State<OutdoorNavigationScreen>
    with SingleTickerProviderStateMixin {
  MaplibreMapController? _mapController;
  bool _isMapReady = false;
  bool _isTransitioningToIndoor = false;
  Symbol? _userMarker;
  StreamSubscription<Position>? _positionStream; // Keep for passive tracking only if needed

  // Animation for smooth marker movement
  late AnimationController _markerAnimationController;
  LatLng? _previousPosition;
  LatLng? _targetPosition;
  double _currentHeading = 0;

  @override
  void initState() {
    super.initState();
    _markerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Match GPS frequency
    )..addListener(_onMarkerAnimationTick);
  }

  void _onMarkerAnimationTick() {
    if (_previousPosition == null || _targetPosition == null || _userMarker == null) return;

    final double t = _markerAnimationController.value;
    final double lat = _previousPosition!.latitude + (_targetPosition!.latitude - _previousPosition!.latitude) * t;
    final double lng = _previousPosition!.longitude + (_targetPosition!.longitude - _previousPosition!.longitude) * t;

    _mapController?.updateSymbol(
      _userMarker!,
      SymbolOptions(
        geometry: LatLng(lat, lng),
        iconRotate: _currentHeading,
      ),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _markerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navProvider, child) {
        // Listen for arrival logic
        if (navProvider.isIndoor &&
            navProvider.isNavigating &&
            !_isTransitioningToIndoor) {
          _isTransitioningToIndoor = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigateToIndoorScreen(context);
          });
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              // Map
              MaplibreMap(
                onMapCreated: _onMapCreated,
                onStyleLoadedCallback: _onStyleLoaded,
                initialCameraPosition: CameraPosition(
                  target:
                      LatLng(AppConstants.campusLat, AppConstants.campusLng),
                  zoom: AppConstants.defaultMapZoom,
                  tilt: 45,
                ),
                styleString: MapStyle.voyager,
                myLocationEnabled: false, // Replaced by custom live tracking
                myLocationRenderMode: MyLocationRenderMode.normal,
                compassEnabled: true,
                attributionButtonPosition: AttributionButtonPosition.bottomLeft,
              ),

              if (!navProvider.isNavigating)
                Positioned(
                  top: 40,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.navigation,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Destination',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                widget.destinationName ??
                                    widget.targetBuilding?.name ??
                                    'Selected Location',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ),

              // Live Tracking Header (Turn by Turn)
              if (navProvider.isNavigating)
                Positioned(
                  top: 50,
                  left: 16,
                  right: 16,
                  child: TurnByTurnWidget(
                    instruction:
                        navProvider.currentInstruction ?? 'Head to destination',
                    distance: navProvider.distanceToDestination != null
                        ? '${navProvider.distanceToDestination!.toStringAsFixed(0)} m'
                        : '...',
                    onClose: () => _stopNavigation(navProvider),
                  ),
                ),

              // Bottom Controls (Preview Card or Live Tracking Stats)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: CustomNavigationControls(
                  isNavigating: navProvider.isNavigating,
                  isLoading: navProvider.isLoadingRoute,
                  instruction: navProvider.currentInstruction ?? 'Follow the route',
                  distance: navProvider.distanceToNextStep != null 
                      ? (navProvider.distanceToNextStep! < 1000 
                          ? '${navProvider.distanceToNextStep!.toStringAsFixed(0)} m'
                          : '${(navProvider.distanceToNextStep! / 1000).toStringAsFixed(1)} km')
                      : (navProvider.distanceToDestination != null
                          ? '${navProvider.distanceToDestination!.toStringAsFixed(0)} m'
                          : '...'),
                  time: navProvider.isNavigating
                      ? (navProvider.remainingTime != null
                          ? '${navProvider.remainingTime} min'
                          : '...')
                      : (navProvider.currentRoute != null
                          ? '${(navProvider.currentRoute!.time / 60000).ceil()} min'
                          : '...'),
                  onStartNavigation: () => _startNavigation(navProvider),
                  onStopNavigation: () => _stopNavigation(navProvider),
                  onConfirmArrival: () =>
                      navProvider.switchToIndoorNavigation(),
                ),
              ),

              // Arrival Dialog
              if (navProvider.isIndoor) _buildArrivalOverlay(),
            ],
          ),
        );
      },
    );
  }

  void _navigateToIndoorScreen(BuildContext context) {
    if (widget.targetBuilding != null && widget.targetEntryPoint != null) {
      setState(() {
        _isMapReady = false; // Disable location on map before navigating
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => IndoorNavigationScreen(
            buildingId: widget.targetBuilding!.id,
            buildingName: widget.targetBuilding!.name,
            floor: 0, // always start at ground floor
            entryPointId: widget.targetEntryPoint!.id,
            destinationLocationId: widget.destinationId,
          ),
        ),
      );
    }
  }

  Widget _buildArrivalOverlay() {
    return Container(
        color: Colors.black54,
        child: Center(
            child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Arrived at ${widget.targetBuilding?.name ?? 'Destination'}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text('Switching to Indoor Navigation...'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary),
                    onPressed: () => _navigateToIndoorScreen(context),
                    child: const Text('Continue Indoors'),
                  ),
                ]))));
  }

  void _onMapCreated(MaplibreMapController controller) {
    _mapController = controller;
  }

  void _onStyleLoaded() {
    setState(() {
      _isMapReady = true;
    });

    // Add 3D Buildings
    _add3DBuildings();

    // Add building markers
    _addBuildingMarkers();

    // If destination coordinates provided, animate to them
    if (widget.destLat != null && widget.destLng != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(widget.destLat!, widget.destLng!),
            zoom: 16,
          ),
        ),
      );

      // Add destination marker
      _addDestinationMarker();
    }

    // Listen to route changes
    final provider = Provider.of<NavigationProvider>(context, listen: false);

    // Automatically preview route
    if (widget.destLat != null &&
        widget.destLng != null &&
        !provider.isNavigating) {
      provider.previewRoute(
        NavigationPoint(lat: widget.destLat!, lng: widget.destLng!),
        targetBuilding: widget.targetBuilding,
        entryPoint: widget.targetEntryPoint,
      );
    }

    provider.addListener(_onProviderUpdated);

    // Kick initial update in case provider already has a route
    _onProviderUpdated();

    // Only start passive tracking if not navigating
    if (!provider.isNavigating) {
      _startPassiveTracking();
    }
  }

  void _startPassiveTracking() async {
    // Check permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (mounted) {
        final navProvider = Provider.of<NavigationProvider>(context, listen: false);
        if (!navProvider.isNavigating) {
          _updateLiveUserMarker(position);
        }
      }
    });
  }

  void _updateLiveUserMarker(Position position) async {
    if (_mapController == null || !_isMapReady) return;

    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final latLng = LatLng(position.latitude, position.longitude);

    if (_userMarker == null) {
      try {
        _userMarker = await _mapController!.addSymbol(
          SymbolOptions(
            geometry: latLng,
            iconImage: 'assets/icons/navigation_marker.png', // Match map style
            iconSize: 0.5,
            iconRotate: position.heading,
          ),
        );
      } catch (e) {
        debugPrint('Error adding real-time user marker: $e');
      }
    } else {
      _mapController!.updateSymbol(
        _userMarker!,
        SymbolOptions(
          geometry: latLng,
          iconRotate: position.heading,
        ),
      );
    }

    // Camera animation should only happen if not being manipulated by the NavigationProvider's active routing
    if (!navProvider.isNavigating) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(
          target: latLng,
          zoom: 18,
          bearing: position.heading,
          tilt: 45,
        )),
        duration: const Duration(milliseconds: 1000),
      );
    }
  }

  void _onProviderUpdated() {
    final provider = Provider.of<NavigationProvider>(context, listen: false);
    if (provider.currentRoute != null && _isMapReady) {
      _drawRoute(
        provider.remainingRouteCoordinates, 
        fullPoints: provider.currentRoute?.coordinates
      );
    }

    // Update user marker and camera
    if (provider.isNavigating &&
        provider.snappedPosition != null &&
        _isMapReady) {
      
      final newPosition = provider.snappedPosition!;
      _currentHeading = provider.currentPosition?.heading ?? 0;

      if (_targetPosition == null) {
        // Initial position
        _previousPosition = newPosition;
        _targetPosition = newPosition;
        _updateUserMarkerNavigating(newPosition, _currentHeading);
      } else if (newPosition != _targetPosition) {
        // New position arrived, start interpolation
        _previousPosition = _targetPosition;
        _targetPosition = newPosition;
        _markerAnimationController.forward(from: 0.0);
      }

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(
          target: newPosition,
          zoom: 19, // Slightly closer for professional feel
          bearing: _currentHeading,
          tilt: 60, // Deep immersive 3D tilt
        )),
        duration: const Duration(milliseconds: 1000), // Smoother camera follow
      );
    }
  }

  Future<void> _add3DBuildings() async {
    if (_mapController == null) return;
    
    try {
      // The Voyager GL style has a 'building' layer in the 'carto' source
      await _mapController!.addLayer(
        "carto",
        "3d-buildings",
        const FillExtrusionLayerProperties(
          fillExtrusionColor: '#E4DCD0',
          fillExtrusionHeight: ["get", "render_height"],
          fillExtrusionBase: ["get", "render_min_height"],
          fillExtrusionOpacity: 0.8,
        ),
        belowLayerId: "place_city_r5", // Place buildings below labels
      );
    } catch (e) {
      debugPrint("Error adding 3D buildings: $e");
    }
  }

  void _updateUserMarkerNavigating(LatLng position, double heading) async {
    if (_mapController == null) return;

    if (_userMarker == null) {
      try {
        _userMarker = await _mapController!.addSymbol(
          SymbolOptions(
            geometry: position,
            iconImage:
                'assets/icons/navigation_marker.png', // We'll assume this exists or use building fallback
            iconSize: 0.5,
            iconRotate: heading,
          ),
        );
      } catch (e) {
        debugPrint('Error adding user marker: $e');
      }
    } else {
      _mapController!.updateSymbol(
          _userMarker!,
          SymbolOptions(
            geometry: position,
            iconRotate: heading,
          ));
    }
  }

  void _drawRoute(List<LatLng> points, {List<LatLng>? fullPoints}) async {
    if (_mapController == null || points.isEmpty) return;

    try {
      // Store current provider to check navigation state
      final provider = Provider.of<NavigationProvider>(context, listen: false);

      await _mapController!.clearLines();

      // 1. Draw Background (Full Route in Gray)
      if (fullPoints != null && fullPoints.isNotEmpty) {
        await _mapController!.addLine(LineOptions(
          geometry: fullPoints,
          lineColor: '#D3D3D3', // Light gray
          lineWidth: 8.0,
          lineOpacity: 0.5,
          lineJoin: 'round',
        ));
      }

      // 2. Draw Foreground (Remaining Route in Blue)
      await _mapController!.addLine(LineOptions(
        geometry: points,
        lineColor: '#1A73E8', // Match Google blue
        lineWidth: 8.0,
        lineOpacity: 0.9,
        lineJoin: 'round',
      ));

      // Fit bounds ONLY if not navigating (i.e., in preview mode)
      if (!provider.isNavigating) {
        LatLngBounds bounds = _getBounds(points);
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds,
              top: 150, left: 50, right: 50, bottom: 250),
        );
      }
    } catch (e) {
      debugPrint('Error drawing route on Maplibre: $e');
    }
  }

  LatLngBounds _getBounds(List<LatLng> points) {
    if (points.isEmpty) {
      // Fallback to campus bounds
      return LatLngBounds(
          southwest: const LatLng(11.3190, 76.0190),
          northeast: const LatLng(11.3210, 76.0210));
    }
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _addBuildingMarkers() async {
    if (_mapController == null) return;

    // TODO: Fetch buildings from Firestore
    List<Map<String, dynamic>> buildings = [
      {
        'id': 'main_building',
        'name': 'Main Building',
        'lat': 11.320,
        'lng': 76.022,
        'type': 'building',
      },
      {
        'id': 'cs_dept',
        'name': 'Computer Science Dept',
        'lat': 11.322,
        'lng': 76.024,
        'type': 'department',
      },
    ];

    for (var building in buildings) {
      try {
        await _mapController!.addSymbol(
          SymbolOptions(
            geometry: LatLng(building['lat'], building['lng']),
            iconImage: 'assets/icons/building_marker.png',
            iconSize: 0.5,
            textField: building['name'],
            textOffset: const Offset(0, 1.5),
            textSize: 12,
            textColor: '#000000',
            textHaloColor: '#FFFFFF',
            textHaloWidth: 2,
          ),
        );
      } catch (e) {
        debugPrint('Error adding building marker: $e');
      }
    }
  }

  void _addDestinationMarker() async {
    if (_mapController == null ||
        widget.destLat == null ||
        widget.destLng == null) return;

    try {
      await _mapController!.addSymbol(
        SymbolOptions(
          geometry: LatLng(
              widget.targetEntryPoint?.latitude ?? widget.destLat!,
              widget.targetEntryPoint?.longitude ?? widget.destLng!),
          iconImage: 'assets/icons/destination_marker.png',
          iconSize: 0.6,
        ),
      );
    } catch (e) {
      debugPrint('Error adding destination marker: $e');
    }
  }

  void _startNavigation(NavigationProvider provider) {
    if (provider.currentRoute != null) {
      provider.startOutdoorNavigation();
    } else {
      final errorMsg =
          provider.routeError ?? 'Unable to calculate route. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    }
  }

  void _stopNavigation(NavigationProvider provider) {
    provider.stopNavigation();
    provider.removeListener(_onProviderUpdated);
    setState(() {
      _isMapReady = false; // Disable location on map
    });
    Navigator.pop(context);
  }
}

class MapStyle {
  static const String voyager = "https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json";
}
