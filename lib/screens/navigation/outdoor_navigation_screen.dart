import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/navigation_provider.dart';
import '../../models/building_model.dart';
import '../../core/constants/app_constants.dart';
import 'widgets/turn_by_turn_widget.dart';
import 'widgets/custom_navigation_controls.dart';
import 'widgets/start_navigation_header.dart';
import 'indoor_navigation_screen.dart';
import '../../core/utils/navigation_utils.dart';
import '../../models/location_model.dart';
import '../../services/firestore_service.dart';

enum MapFollowMode { northUp, headingUp }

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
  // ── Map ──────────────────────────────────────────────────────────────────
  MaplibreMapController? _mapController;
  bool _isMapReady = false;
  bool _isTransitioningToIndoor = false;
  bool _isCentered = true;
  double _currentBearing = 0.0;
  MapFollowMode _followMode = MapFollowMode.northUp;
  bool _isAutoRotating = false;
  DateTime? _lastDrawTimestamp; // Throttling map drawing
  bool _hasSpokenDestination = false;
  LocationModel? _destinationLocation;
  final FirestoreService _firestoreService = FirestoreService();

  // ── User Marker (smooth animated blue dot) ────────────────────────────
  Symbol? _userMarker;
  late AnimationController _markerAnimationController;
  LatLng? _previousPosition;
  LatLng? _targetPosition;
  double _currentHeading = 0;

  // ── Passive tracking (pre-navigation) ────────────────────────────────
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _markerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(_onMarkerAnimationTick);
    _fetchDestinationDetails();
  }

  Future<void> _fetchDestinationDetails() async {
    if (widget.destinationId != null) {
      final loc = await _firestoreService.getLocation(widget.destinationId!);
      if (mounted) {
        setState(() => _destinationLocation = loc);
      }
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _markerAnimationController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────
  // Marker animation (smooth interpolation between GPS positions)
  // ─────────────────────────────────────────────────────────────────
  void _onMarkerAnimationTick() {
    if (_previousPosition == null ||
        _targetPosition == null ||
        _mapController == null) return;

    final double t = _markerAnimationController.value;
    final double lat = _previousPosition!.latitude +
        (_targetPosition!.latitude - _previousPosition!.latitude) * t;
    final double lng = _previousPosition!.longitude +
        (_targetPosition!.longitude - _previousPosition!.longitude) * t;

    final LatLng interpPos = LatLng(lat, lng);
    final provider = Provider.of<NavigationProvider>(context, listen: false);
    final double accuracy = provider.currentPosition?.accuracy ?? 20.0;

    _updateUserLocationGeoJson(interpPos, _currentHeading, accuracy);
  }

  // ─────────────────────────────────────────────────────────────────
  // Map Lifecycle
  // ─────────────────────────────────────────────────────────────────
  void _onMapCreated(MaplibreMapController controller) {
    _mapController = controller;

    // Track bearing for compass button visibility
    controller.addListener(() {
      if (!mounted) return;
      final bearing = controller.cameraPosition?.bearing ?? 0.0;
      if ((bearing - _currentBearing).abs() > 0.5) {
        setState(() => _currentBearing = bearing);
      }
    });
  }

  void _onStyleLoaded() {
    setState(() => _isMapReady = true);

    _initRouteLayers();
    _initUserLocationLayers();
    _add3DBuildings();
    _addBuildingMarkers();

    if (widget.destLat != null && widget.destLng != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(widget.destLat!, widget.destLng!),
            zoom: 16,
          ),
        ),
      );
      _addDestinationMarker();
    }

    final provider = Provider.of<NavigationProvider>(context, listen: false);

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
    _onProviderUpdated();

    if (!provider.isNavigating) {
      _startPassiveTracking();
      // Speak destination flow on load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasSpokenDestination) {
          _hasSpokenDestination = true;
          final building = widget.targetBuilding?.name ?? "Destination";
          final floor = _destinationLocation?.floor == 0 ? "Ground Floor" 
              : (_destinationLocation?.floor == 1 ? "First Floor" 
              : (_destinationLocation?.floor == 2 ? "Second Floor" 
              : (_destinationLocation?.floor == 3 ? "Third Floor" 
              : (_destinationLocation?.floor != null ? "Floor ${_destinationLocation!.floor}" : "Second Floor"))));
          final cabin = widget.destinationName ?? "";
          provider.speak("Navigating to $building. Flow: $building, $floor, $cabin.");
        }
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Camera Controls
  // ─────────────────────────────────────────────────────────────────
  void _recenter() {
    final provider = Provider.of<NavigationProvider>(context, listen: false);
    final pos = provider.currentPosition;
    if (pos != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(pos.latitude, pos.longitude),
            zoom: 18,
            bearing: pos.heading,
            tilt: 45,
          ),
        ),
        duration: const Duration(milliseconds: 800),
      );
      setState(() => _isCentered = true);
    } else if (_targetPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_targetPosition!),
        duration: const Duration(milliseconds: 800),
      );
      setState(() => _isCentered = true);
    }
  }

  void _resetNorth() {
    _mapController?.animateCamera(
      CameraUpdate.bearingTo(0),
      duration: const Duration(milliseconds: 500),
    );
    setState(() => _currentBearing = 0.0);
    setState(() => _followMode = MapFollowMode.northUp);
  }

  void _toggleFollowMode() {
    setState(() {
      _followMode = _followMode == MapFollowMode.northUp
          ? MapFollowMode.headingUp
          : MapFollowMode.northUp;
      
      if (_followMode == MapFollowMode.northUp) {
        _resetNorth();
      } else {
        _recenter();
      }
    });
  }

  void _zoomIn() => _mapController?.animateCamera(
        CameraUpdate.zoomIn(),
        duration: const Duration(milliseconds: 300),
      );

  void _zoomOut() => _mapController?.animateCamera(
        CameraUpdate.zoomOut(),
        duration: const Duration(milliseconds: 300),
      );

  // ─────────────────────────────────────────────────────────────────
  // Passive Location Tracking (pre-navigation)
  // ─────────────────────────────────────────────────────────────────
  void _startPassiveTracking() async {
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
      if (!mounted) return;
      final navProvider =
          Provider.of<NavigationProvider>(context, listen: false);
      if (!navProvider.isNavigating) {
        _updateLiveUserMarker(position);
      }
    });
  }


  void _updateLiveUserMarker(Position position) async {
    if (_mapController == null || !_isMapReady) return;

    final latLng = LatLng(position.latitude, position.longitude);
    _currentHeading = position.heading;

    if (_targetPosition == null) {
      _previousPosition = latLng;
      _targetPosition = latLng;
      _updateUserLocationGeoJson(latLng, _currentHeading, position.accuracy);
    } else if (latLng != _targetPosition) {
      _previousPosition = _targetPosition;
      _targetPosition = latLng;
      _markerAnimationController.forward(from: 0.0);
    }

    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    if (!navProvider.isNavigating) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(
          target: latLng,
          zoom: 18,
          bearing: position.heading,
          tilt: 45,
        )),
        duration: const Duration(milliseconds: 800),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Provider Updates (during active navigation)
  // ─────────────────────────────────────────────────────────────────
  void _onProviderUpdated() {
    final provider = Provider.of<NavigationProvider>(context, listen: false);

    if (provider.currentRoute != null && _isMapReady) {
      _drawRoute(
        provider.remainingRouteCoordinates,
        fullPoints: provider.currentRoute?.coordinates,
      );
    }

    if (provider.isNavigating &&
        provider.snappedPosition != null &&
        _isMapReady) {
      final newPosition = provider.snappedPosition!;
      _currentHeading = provider.currentPosition?.heading ?? 0;

      if (_targetPosition == null) {
        _previousPosition = newPosition;
        _targetPosition = newPosition;
        _updateUserMarkerNavigating(newPosition, _currentHeading);
      } else if (newPosition != _targetPosition) {
        _previousPosition = _targetPosition;
        _targetPosition = newPosition;
        _markerAnimationController.forward(from: 0.0);
      }

      if (_isCentered) {
        final double targetBearing = (_followMode == MapFollowMode.headingUp) ? _currentHeading : 0;
        
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(CameraPosition(
            target: newPosition,
            zoom: 19,
            bearing: targetBearing,
            tilt: 55,
          )),
          duration: const Duration(milliseconds: 900),
        );
      }
    }
  }

  // Removed invalid _updateUserLocationLayersForMode method as 'map' alignment 
  // already correctly points the icon 'Up' when map bearing matches user heading.

  // ─────────────────────────────────────────────────────────────────
  // Map Layers
  // ─────────────────────────────────────────────────────────────────
  Future<void> _add3DBuildings() async {
    if (_mapController == null) return;
    try {
      await _mapController!.addLayer(
        "carto",
        "3d-buildings",
        const FillExtrusionLayerProperties(
          fillExtrusionColor: '#E0E0E0', 
          fillExtrusionHeight: ["get", "render_height"],
          fillExtrusionBase: ["get", "render_min_height"],
          fillExtrusionOpacity: 0.7,
        ),
        belowLayerId: "place_city_r5",
        minzoom: 15.0,
      );
    } catch (e) {
      debugPrint("Error adding 3D buildings: $e");
    }
  }

  Future<void> _initRouteLayers() async {
    if (_mapController == null) return;
    try {
      // 1. Add Traveled Route Source & Layer
      await _mapController!.addSource("route-traveled-source",
          const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}));
      await _mapController!.addLayer(
        "route-traveled-source",
        "route-traveled",
        const LineLayerProperties(
          lineColor: '#3a4060',
          lineWidth: 6.0,
          lineOpacity: 0.6,
          lineJoin: 'round',
          lineCap: 'round',
        ),
      );

      // 2. Add Active Route Glow Source & Layer (The outer white glow)
      await _mapController!.addSource("route-source",
          const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}));

      await _mapController!.addLayer(
        "route-source",
        "route-glow",
        const LineLayerProperties(
          lineColor: '#FFFFFF',
          lineWidth: 10.0,
          lineOpacity: 0.25,
          lineJoin: 'round',
          lineCap: 'round',
        ),
        belowLayerId: "3d-buildings", // Under buildings and custom markers
      );

      // 3. Add Active Route Main Layer (The blue dotted line)
      await _mapController!.addLayer(
        "route-source",
        "route-main",
        const LineLayerProperties(
          lineColor: '#3b82f6', // Premium Google blue
          lineWidth: 6.0,
          lineJoin: 'round',
          lineCap: 'round',
          lineDasharray: [0.1, 1.8], // Dotted pattern
        ),
        belowLayerId: "3d-buildings",
      );

      // 4. Add Active Segment Highlight Source & Layer (The solid blue line for current leg)
      await _mapController!.addSource("route-segment-source",
          const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}));

      await _mapController!.addLayer(
        "route-segment-source",
        "route-segment-highlight",
        const LineLayerProperties(
          lineColor: '#3b82f6', // Same blue but solid
          lineWidth: 6.0,
          lineJoin: 'round',
          lineCap: 'round',
        ),
        belowLayerId: "3d-buildings",
      );
    } catch (e) {
      debugPrint("Error initializing route layers: $e");
    }
  }

  Future<void> _initUserLocationLayers() async {
    if (_mapController == null) return;
    try {
      await _mapController!.addSource("user-location-source",
          const GeojsonSourceProperties(data: {"type": "FeatureCollection", "features": []}));

      // 1. Accuracy Circle (Bottom-most)
      await _mapController!.addLayer(
        "user-location-source",
        "user-location-accuracy",
        const CircleLayerProperties(
          circleColor: '#3b82f6',
          circleOpacity: 0.15,
          circleRadius: 40.0, // Fixed radius for visual feedback
          circleBlur: 0.5,
        ),
      );

      // 2. White Halo for the Blue Dot
      await _mapController!.addLayer(
        "user-location-source",
        "user-location-halo",
        const CircleLayerProperties(
          circleColor: '#FFFFFF',
          circleRadius: 10.0,
          circleOpacity: 1.0,
        ),
      );

      // 3. Blue Dot (Center)
      await _mapController!.addLayer(
        "user-location-source",
        "user-location-dot",
        const CircleLayerProperties(
          circleColor: '#3b82f6',
          circleRadius: 8.0,
          circleOpacity: 1.0,
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 0.5,
        ),
      );

      // 4. Heading Arrow (Top-most)
      await _mapController!.addLayer(
        "user-location-source",
        "user-location-arrow",
        const SymbolLayerProperties(
          iconImage: 'assets/icons/navigation_marker.png',
          iconSize: 0.45,
          iconRotate: ["get", "bearing"],
          iconRotationAlignment: 'map',
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
        ),
      );
    } catch (e) {
      debugPrint("Error initializing user location layers: $e");
    }
  }

  void _updateUserLocationGeoJson(LatLng pos, double heading, double accuracy) async {
    if (_mapController == null) return;
    
    final geojson = {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [pos.longitude, pos.latitude],
          },
          "properties": {
            "bearing": heading,
            "accuracy": accuracy,
          },
        }
      ]
    };

    await _mapController!.setGeoJsonSource("user-location-source", geojson);
  }

  void _updateUserMarkerNavigating(LatLng position, double heading) async {
    // No longer using single symbol, handled by GeoJSON layers
  }

  void _drawRoute(List<LatLng> points, {List<LatLng>? fullPoints}) async {
    if (_mapController == null || points.isEmpty) return;

    // Performance Optimization: Throttle drawing to ~10-15 FPS (every 100ms)
    // for complex polyline updates to stay smooth on low-end devices.
    final now = DateTime.now();
    if (_lastDrawTimestamp != null) {
      if (now.difference(_lastDrawTimestamp!).inMilliseconds < 100) {
        return;
      }
    }
    _lastDrawTimestamp = now;

    try {
      final provider = Provider.of<NavigationProvider>(context, listen: false);

      // 1. Update Active Route (Main + Glow)
      final activeGeoJson = NavigationUtils.toGeoJson(points);
      await _mapController!.setGeoJsonSource("route-source", activeGeoJson);

      // 1.5 Update Active Segment (Next Leg)
      if (provider.isNavigating) {
        final segmentGeoJson = NavigationUtils.toGeoJson(provider.nextSegmentCoordinates);
        await _mapController!.setGeoJsonSource("route-segment-source", segmentGeoJson);
      }

      // 2. Update Traveled Route
      if (fullPoints != null && fullPoints.isNotEmpty) {
        // Assume points is a sublist of fullPoints (remaining points)
        // Everything before 'points.first' in 'fullPoints' is traveled
        int firstIndex = 0;
        for (int i = 0; i < fullPoints.length; i++) {
          if (fullPoints[i].latitude == points.first.latitude &&
              fullPoints[i].longitude == points.first.longitude) {
            firstIndex = i;
            break;
          }
        }

        if (firstIndex > 0) {
          final traveledPoints = fullPoints.sublist(0, firstIndex + 1);
          final traveledGeoJson = NavigationUtils.toGeoJson(traveledPoints);
          await _mapController!.setGeoJsonSource("route-traveled-source", traveledGeoJson);
        } else {
          // Clear traveled source if we are at the beginning
          await _mapController!.setGeoJsonSource("route-traveled-source",
              {"type": "FeatureCollection", "features": []});
        }
      }

      if (!provider.isNavigating) {
        LatLngBounds bounds = _getBounds(points);
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds,
              top: 150, left: 50, right: 50, bottom: 250),
        );
      }
    } catch (e) {
      debugPrint('Error drawing route: $e');
    }
  }

  LatLngBounds _getBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
          southwest: const LatLng(11.3190, 75.9310),
          northeast: const LatLng(11.3210, 75.9340));
    }
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _addBuildingMarkers() async {
    if (_mapController == null) return;

    final buildings = [
      {'name': 'Main Building', 'lat': 11.320, 'lng': 75.932},
      {'name': 'CS Dept', 'lat': 11.322, 'lng': 75.934},
    ];

    for (var b in buildings) {
      try {
        await _mapController!.addSymbol(
          SymbolOptions(
            geometry: LatLng(b['lat'] as double, b['lng'] as double),
            iconImage: 'assets/icons/building_marker.png',
            iconSize: 0.5,
            textField: b['name'] as String,
            textOffset: const Offset(0, 1.5),
            textSize: 12,
            textColor: '#FFFFFF',
            textHaloColor: '#000000',
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
            widget.targetEntryPoint?.longitude ?? widget.destLng!,
          ),
          iconImage: 'assets/icons/destination_marker.png',
          iconSize: 0.6,
        ),
      );
    } catch (e) {
      debugPrint('Error adding destination marker: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Navigation Actions
  // ─────────────────────────────────────────────────────────────────
  void _startNavigation(NavigationProvider provider) {
    if (provider.currentRoute != null) {
      provider.startOutdoorNavigation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              provider.routeError ?? 'Unable to calculate route. Try again.'),
          backgroundColor: const Color(0xFF1C2333),
        ),
      );
    }
  }

  void _stopNavigation(NavigationProvider provider) {
    provider.stopNavigation();
    provider.removeListener(_onProviderUpdated);
    Navigator.pop(context);
  }

  void _navigateToIndoorScreen(BuildContext context) {
    if (widget.targetBuilding != null && widget.targetEntryPoint != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => IndoorNavigationScreen(
            buildingId: widget.targetBuilding!.id,
            buildingName: widget.targetBuilding!.name,
            floor: 0,
            entryPointId: widget.targetEntryPoint!.id,
            destinationLocationId: widget.destinationId,
          ),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    const bool showCompass = true;

    return Consumer<NavigationProvider>(
      builder: (context, navProvider, child) {
        // Trigger indoor transition
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
              // ── MapLibre Map (Dark Matter) ─────────────────────────────
              MaplibreMap(
                onMapCreated: _onMapCreated,
                onStyleLoadedCallback: _onStyleLoaded,
                initialCameraPosition: const CameraPosition(
                  target: LatLng(AppConstants.campusLat, AppConstants.campusLng),
                  zoom: AppConstants.defaultMapZoom,
                  tilt: 45,
                ),
                styleString: _NavMapStyle.positron,
                myLocationEnabled: false, // custom marker for smooth animation
                myLocationRenderMode: MyLocationRenderMode.normal,
                compassEnabled: false, // custom compass button
                attributionButtonPosition: AttributionButtonPosition.bottomLeft,
                zoomGesturesEnabled: true,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
                scrollGesturesEnabled: true,
              ),

              // ── Pre-navigation Destination Header ──────────────────────
              if (!navProvider.isNavigating)
                Positioned(
                  top: 50,
                  left: 16,
                  right: 16,
                  child: StartNavigationHeader(
                    buildingName: widget.targetBuilding?.name ?? "Building",
                    floorNumber: _destinationLocation?.floor,
                    cabinName: widget.destinationName ?? "Cabin",
                    isSpeaking: navProvider.isSpeaking,
                  ),
                ),

              // ── Turn-by-Turn Header ────────────────────────────────────
              if (navProvider.isNavigating)
                Positioned(
                  top: 50,
                  left: 16,
                  right: 16,
                  child: TurnByTurnWidget(
                    instruction: navProvider.currentInstruction ??
                        'Head to destination',
                    distance: navProvider.distanceToNextStep != null
                        ? (navProvider.distanceToNextStep! < 1000
                            ? 'In ${navProvider.distanceToNextStep!.toStringAsFixed(0)} m'
                            : 'In ${(navProvider.distanceToNextStep! / 1000).toStringAsFixed(1)} km')
                        : '...',
                    sign: navProvider.currentSign,
                    nextInstruction: navProvider.nextInstruction,
                    nextSign: navProvider.nextSign,
                    isSpeaking: navProvider.isSpeaking,
                    onClose: () => _stopNavigation(navProvider),
                  ),
                ),

              // ── Top-Right Floating Button Stack ──────────────────────
              if (navProvider.isNavigating)
                SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, top: 110),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Compass
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _NavFloatingButton(
                            child: Transform.rotate(
                              angle: -_currentBearing * 3.14159265 / 180,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(Icons.navigation,
                                      color: Colors.white, size: 26),
                                  ClipRect(
                                    clipper: _TopHalfClipper(),
                                    child: const Icon(Icons.navigation,
                                        color: Colors.redAccent, size: 26),
                                  ),
                                ],
                              ),
                            ),
                            onTap: _resetNorth,
                          ),
                        ),
                        

                        // 2. Voice Toggle (if navigating)
                        if (navProvider.isNavigating)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _NavFloatingButton(
                              child: Icon(
                                navProvider.isVoiceEnabled
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_off_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              onTap: navProvider.toggleVoice,
                            ),
                          ),

                        // 4. Follow Mode Toggle
                        if (!navProvider.isNavigating)
                          _NavFloatingButton(
                            child: Icon(
                              _followMode == MapFollowMode.headingUp
                                  ? Icons.navigation_rounded
                                  : Icons.explore_rounded,
                              color: _followMode == MapFollowMode.headingUp
                                  ? Colors.blueAccent
                                  : Colors.white,
                              size: 24,
                            ),
                            onTap: _toggleFollowMode,
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Zoom Controls (right-side) ─────────────────────────────
              if (navProvider.isNavigating)
                Positioned(
                  right: 16,
                  bottom: 160,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _NavFloatingButton(
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 24),
                        onTap: _zoomIn,
                      ),
                      const SizedBox(height: 12),
                      _NavFloatingButton(
                        child: const Icon(Icons.remove,
                            color: Colors.white, size: 24),
                        onTap: _zoomOut,
                      ),
                    ],
                  ),
                ),

              // ── Recenter Button (bottom-left) ──────────────────────────
              if (!_isCentered)
                Positioned(
                  bottom: navProvider.isNavigating ? 140 : 160,
                  left: 16,
                  child: _RecenterPill(onTap: _recenter),
                ),

              // ── Bottom Navigation Controls ─────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: CustomNavigationControls(
                  isNavigating: navProvider.isNavigating,
                  isLoading: navProvider.isLoadingRoute,
                  instruction: navProvider.isNavigating
                      ? (navProvider.currentInstruction ?? 'Follow the route')
                      : (widget.targetBuilding?.name ?? 'Head to Entrance'),
                  distance: navProvider.distanceToDestination != null
                      ? (navProvider.distanceToDestination! < 1000
                          ? '${navProvider.distanceToDestination!.toStringAsFixed(0)} m'
                          : '${(navProvider.distanceToDestination! / 1000).toStringAsFixed(1)} km')
                      : '...',
                  time: navProvider.remainingTime != null
                      ? '${navProvider.remainingTime} min'
                      : (navProvider.currentRoute != null
                          ? '${(navProvider.currentRoute!.time / 60000).ceil()} min'
                          : '...'),
                  arrivalTime: navProvider.arrivalTime,
                  base64Image: widget.targetEntryPoint?.imageUrl ?? widget.targetBuilding?.imageUrl,
                  onStartNavigation: () => _startNavigation(navProvider),
                  onStopNavigation: () => _stopNavigation(navProvider),
                  onConfirmArrival: () =>
                      navProvider.switchToIndoorNavigation(),
                ),
              ),

              // ── Arrival Overlay ────────────────────────────────────────
              if (navProvider.isIndoor) _buildArrivalOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArrivalOverlay() {
    return Container(
      color: Colors.black26,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.black, size: 64),
              const SizedBox(height: 16),
              Text(
                'Arrived at ${widget.targetBuilding?.name ?? 'Destination'}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Switching to Indoor Navigation...',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 16),
                ),
                onPressed: () => _navigateToIndoorScreen(context),
                child: const Text(
                  'Continue Indoors',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Destination Preview Card
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
class _NavFloatingButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _NavFloatingButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      shadowColor: Colors.black45,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(width: 46, height: 46, child: Center(child: child)),
      ),
    );
  }
}

class _RecenterPill extends StatelessWidget {
  final VoidCallback onTap;
  const _RecenterPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.rotate(
                angle: -0.785,
                child: const Icon(Icons.navigation,
                    color: Colors.black, size: 18),
              ),
              const SizedBox(width: 8),
              const Text(
                'Re-centre',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map Style
// ─────────────────────────────────────────────────────────────────────────────

class _NavMapStyle {
  static const String darkMatter =
      'https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json';
  static const String positron =
      'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json';
}

class _TopHalfClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width, size.height / 2);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}
