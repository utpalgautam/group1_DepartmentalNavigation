import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../models/building_model.dart';
import '../services/graphhopper_service.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/navigation_utils.dart';

class NavigationPoint {
  final double lat;
  final double lng;

  const NavigationPoint({required this.lat, required this.lng});
}

class NavigationProvider extends ChangeNotifier {
  final GraphHopperService _graphHopperService = GraphHopperService();
  
  bool _isNavigating = false;
  bool _isIndoor = false;
  bool _isLoadingRoute = false;
  bool _isRerouting = false;
  
  NavigationPoint? _destination;
  EntryPoint? _targetEntryPoint;
  BuildingModel? _targetBuilding;

  NavigationRoute? _currentRoute;
  String? _currentInstruction;
  int _currentInstructionIndex = 0;
  double? _distanceToDestination;
  String? _routeError;
  List<LatLng> _remainingRouteCoordinates = [];
  
  Position? _currentPosition; // Raw filtered position
  LatLng? _snappedPosition; // Snapped and smoothed for UI
  Position? _lastRawPosition; // Used for smoothing
  DateTime? _lastRerouteTime; // Throttling reroutes
  
  StreamSubscription<Position>? _positionStreamSubscription;

  bool get isNavigating => _isNavigating;
  bool get isIndoor => _isIndoor;
  bool get isLoadingRoute => _isLoadingRoute;
  
  NavigationPoint? get destination => _destination;
  EntryPoint? get targetEntryPoint => _targetEntryPoint;
  BuildingModel? get targetBuilding => _targetBuilding;

  NavigationRoute? get currentRoute => _currentRoute;
  List<LatLng> get remainingRouteCoordinates => 
      _remainingRouteCoordinates.isNotEmpty ? _remainingRouteCoordinates : (_currentRoute?.coordinates ?? []);
  String? get currentInstruction => _currentInstruction;
  double? get distanceToDestination => _distanceToDestination;
  int? get remainingTime {
    if (_distanceToDestination == null || _currentRoute == null || _currentRoute!.distance == 0) return null;
    // Simple proportional estimation: (remainingDist / totalDist) * totalTime
    double ratio = _distanceToDestination! / _currentRoute!.distance;
    return (ratio * (_currentRoute!.time / 60000)).ceil();
  }
  String? get routeError => _routeError;
  Position? get currentPosition => _currentPosition;
  LatLng? get snappedPosition => _snappedPosition ?? (_currentPosition != null ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) : null);

  Future<void> previewRoute(
      NavigationPoint destination, {
      BuildingModel? targetBuilding,
      EntryPoint? entryPoint,
  }) async {
    _destination = destination;
    _targetBuilding = targetBuilding;
    _targetEntryPoint = entryPoint;
    _isLoadingRoute = true;
    _routeError = null;
    _remainingRouteCoordinates = [];
    notifyListeners();

    // 1. Warm up server (Anti-Cold Start)
    _currentInstruction = "Waking up server...";
    notifyListeners();
    await _graphHopperService.warmup();

    // 2. Get current location
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation);
    } catch (e) {
      debugPrint("Error getting location: $e");
      // Fallback to campus center for preview if location fails
      _currentPosition = Position(
        latitude: AppConstants.campusLat,
        longitude: AppConstants.campusLng,
        timestamp: DateTime.now(),
        accuracy: 100.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }

    if (_currentPosition != null) {
      // If user is far from campus, clamp to campus center for testing
      double distanceToCampus = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        AppConstants.campusLat,
        AppConstants.campusLng,
      );
      
      if (distanceToCampus > 2000) {
        _currentPosition = Position(
          latitude: AppConstants.campusLat,
          longitude: AppConstants.campusLng,
          timestamp: DateTime.now(),
          accuracy: 100.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      }

      await _fetchRoute();
    }
    
    _isLoadingRoute = false;
    notifyListeners();
  }

  Future<void> _fetchRoute() async {
    if (_currentPosition == null || _destination == null) return;

    final start = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final end = LatLng(_destination!.lat, _destination!.lng);
    
    try {
      final route = await _graphHopperService.getRoute(start, end);
      if (route != null) {
        _currentRoute = route;
        _currentInstructionIndex = 0;
        if (_currentRoute!.instructions.isNotEmpty) {
          _currentInstruction = _currentRoute!.instructions.first.text;
        }
        _distanceToDestination = _currentRoute!.distance;
        _remainingRouteCoordinates = List.from(_currentRoute!.coordinates);
      }
    } catch (e) {
      _routeError = e.toString();
      debugPrint('NavigationProvider Route Error: $_routeError');
    }
  }

  Future<void> startOutdoorNavigation() async {
    if (_destination == null || _currentRoute == null) return;
    
    _isNavigating = true;
    _isIndoor = false;
    _remainingRouteCoordinates = List.from(_currentRoute!.coordinates);
    _snappedPosition = null;
    _lastRawPosition = null;
    _currentInstructionIndex = 0;
    if (_currentRoute!.instructions.isNotEmpty) {
      _currentInstruction = _currentRoute!.instructions.first.text;
    }
    notifyListeners();

    // Start live tracking
    _startLocationTracking();
  }

  void _startLocationTracking() {
    _positionStreamSubscription?.cancel();

    // High frequency updates: 1 second interval, 1 meter distance filter
    // Use platform-specific settings for more reliability if available
    final LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
        intervalDuration: const Duration(seconds: 1),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Navigation is in progress",
          notificationTitle: "NITC Campus Navigator",
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
      );
    }

    _positionStreamSubscription = Geolocator.getPositionStream(
            locationSettings: locationSettings)
        .listen((Position? position) {
      if (position != null) {
        _handlePositionUpdate(position);
      }
    });
  }

  void _handlePositionUpdate(Position position) {
    // 1. Accuracy Filtering: Ignore readings > 25 meters
    if (position.accuracy > 25) {
      debugPrint("Ignoring low accuracy GPS reading: ${position.accuracy}m");
      return;
    }

    _currentPosition = position;
    LatLng newLatLng = LatLng(position.latitude, position.longitude);

    // 2. Smoothing: weighted average (0.7 * previous + 0.3 * current)
    // We use the last smoothed/snapped position if available for continuity
    if (_snappedPosition != null) {
      newLatLng = NavigationUtils.smoothCoordinates(
        _snappedPosition!,
        newLatLng,
        alpha: 0.3, // Matches (0.7 * previous + 0.3 * new)
      );
    }
    _lastRawPosition = position;

    if (_currentRoute != null && _currentRoute!.coordinates.isNotEmpty) {
      // 3. Snapping
      final snapResult = NavigationUtils.snapToPolyline(newLatLng, _currentRoute!.coordinates);
      LatLng snapped = snapResult['point'];
      double distFromRoute = snapResult['distance'];
      int segmentIndex = snapResult['index'];

      // Only snap if we are within 15 meters of the route
      if (distFromRoute < 15.0) {
        _snappedPosition = snapped;
      } else {
        _snappedPosition = newLatLng;
      }

      // 4. Deviation Detection: Trigger reroute if > 20m away and not recently rerouted (5s)
      if (distFromRoute > 20.0 && !_isRerouting) {
        final now = DateTime.now();
        if (_lastRerouteTime == null || now.difference(_lastRerouteTime!).inSeconds >= 5) {
          _triggerReroute();
        } else {
          debugPrint("Deviation detected, but throttling reroute (last was < 5s ago)");
        }
      }

    // 5. Progress Tracking (Update Remaining Route & Distance)
    _updateProgress(snapped, segmentIndex);
    
    // 6. Update Turn-by-Turn Instructions
    _updateInstructions(snapped, segmentIndex);
    
    // 7. Arrival Detection
    _checkArrival(position);
    } else {
      _snappedPosition = newLatLng;
    }

    notifyListeners();
  }

  void _updateProgress(LatLng snappedOnRoute, int segmentIndex) {
    if (_currentRoute == null) return;

    // Shrink the displayed route from the snapped point onwards
    _remainingRouteCoordinates = _currentRoute!.coordinates.sublist(segmentIndex);
    if (_remainingRouteCoordinates.isNotEmpty) {
        // Replace the first point of remaining route with the actual snapped point for visual accuracy
        _remainingRouteCoordinates[0] = snappedOnRoute;
    }

    // Calculate actual remaining distance along polyline
    _distanceToDestination = NavigationUtils.calculatePolylineDistance(_remainingRouteCoordinates);
  }

  void _updateInstructions(LatLng snapped, int segmentIndex) {
    if (_currentRoute == null || _currentRoute!.instructions.isEmpty) return;

    // 1. Advance instruction if we passed its start node
    while (_currentInstructionIndex + 1 < _currentRoute!.instructions.length &&
           segmentIndex >= _currentRoute!.instructions[_currentInstructionIndex + 1].interval[0]) {
      _currentInstructionIndex++;
      _currentInstruction = _currentRoute!.instructions[_currentInstructionIndex].text;
    }

    // 2. Proximity check for the NEXT instruction
    if (_currentInstructionIndex + 1 < _currentRoute!.instructions.length) {
      final nextInst = _currentRoute!.instructions[_currentInstructionIndex + 1];
      final nextPoint = _currentRoute!.coordinates[nextInst.interval[0]];
      
      double distToNext = NavigationUtils.calculateDistance(snapped, nextPoint);
      
      // If within 40m, show the upcoming instruction
      if (distToNext < 40.0) {
        _currentInstruction = nextInst.text;
      } else {
        // Otherwise keep the current one
        _currentInstruction = _currentRoute!.instructions[_currentInstructionIndex].text;
      }
    }
  }

  Future<void> _triggerReroute() async {
    if (_isRerouting || _currentPosition == null || _destination == null) return;
    
    debugPrint("Route deviation detected (>20m). Triggering reroute...");
    _isRerouting = true;
    _lastRerouteTime = DateTime.now();
    _currentInstruction = "Rerouting...";
    notifyListeners();

    try {
      await _fetchRoute();
      if (_currentRoute != null) {
        _remainingRouteCoordinates = List.from(_currentRoute!.coordinates);
        _currentInstruction = _currentRoute!.instructions.isNotEmpty 
            ? _currentRoute!.instructions.first.text 
            : "Follow the new route";
      }
    } catch (e) {
      debugPrint("Rerouting failed: $e");
    } finally {
      _isRerouting = false;
      notifyListeners();
    }
  }

  void _checkArrival(Position position) {
    if (_targetEntryPoint != null) {
      double distanceToEntry = NavigationUtils.calculateDistance(
        LatLng(position.latitude, position.longitude),
        LatLng(_targetEntryPoint!.latitude, _targetEntryPoint!.longitude),
      );

      if (distanceToEntry <= AppConstants.entryPointRadius && !_isIndoor) {
        _triggerIndoorArrival();
      }
    } else if (_destination != null) {
       double distanceToDest = NavigationUtils.calculateDistance(
        LatLng(position.latitude, position.longitude),
        LatLng(_destination!.lat, _destination!.lng),
      );
      
      if (distanceToDest <= 10.0 && !_isIndoor) {
          _currentInstruction = "You have arrived at your destination.";
      }
    }
  }

  void _triggerIndoorArrival() {
    _currentInstruction = 'You have arrived at ${_targetEntryPoint?.label ?? 'the entrance'}. Switch to indoor navigation.';
    switchToIndoorNavigation();
  }

  void switchToIndoorNavigation() {
    _isIndoor = true;
    _positionStreamSubscription?.cancel();
    notifyListeners();
  }

  void stopNavigation() {
    _isNavigating = false;
    _isIndoor = false;
    _destination = null;
    _targetEntryPoint = null;
    _targetBuilding = null;
    _currentRoute = null;
    _currentInstruction = null;
    _distanceToDestination = null;
    _snappedPosition = null;
    _lastRawPosition = null;
    _isRerouting = false;
    
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    
    notifyListeners();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}
