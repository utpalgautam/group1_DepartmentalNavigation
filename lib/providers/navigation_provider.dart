import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../models/building_model.dart';
import '../services/graphhopper_service.dart';
import '../core/constants/app_constants.dart';

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
  
  NavigationPoint? _destination;
  EntryPoint? _targetEntryPoint;
  BuildingModel? _targetBuilding;

  NavigationRoute? _currentRoute;
  String? _currentInstruction;
  double? _distanceToDestination;
  
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  bool get isNavigating => _isNavigating;
  bool get isIndoor => _isIndoor;
  bool get isLoadingRoute => _isLoadingRoute;
  
  NavigationPoint? get destination => _destination;
  EntryPoint? get targetEntryPoint => _targetEntryPoint;
  BuildingModel? get targetBuilding => _targetBuilding;

  NavigationRoute? get currentRoute => _currentRoute;
  String? get currentInstruction => _currentInstruction;
  double? get distanceToDestination => _distanceToDestination;
  Position? get currentPosition => _currentPosition;

  Future<void> previewRoute(
      NavigationPoint destination, {
      BuildingModel? targetBuilding,
      EntryPoint? entryPoint,
  }) async {
    _destination = destination;
    _targetBuilding = targetBuilding;
    _targetEntryPoint = entryPoint;
    _isLoadingRoute = true;
    notifyListeners();

    // Get current location
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
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
      final start = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      final end = LatLng(destination.lat, destination.lng);
      
      _currentRoute = await _graphHopperService.getRoute(start, end);
      
      if (_currentRoute != null && _currentRoute!.instructions.isNotEmpty) {
        _currentInstruction = _currentRoute!.instructions.first.text;
        _distanceToDestination = _currentRoute!.distance;
      }
    }
    
    _isLoadingRoute = false;
    notifyListeners();
  }

  Future<void> startOutdoorNavigation() async {
    if (_destination == null || _currentRoute == null) return;
    
    _isNavigating = true;
    _isIndoor = false;
    notifyListeners();

    // Start live tracking
    _startLocationTracking();
  }

  void _startLocationTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // update every 5 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
            locationSettings: locationSettings)
        .listen((Position? position) {
      if (position != null) {
        _currentPosition = position;
        
        if (_destination != null) {
          // Calculate distance to destination
          double distanceInMeters = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            _destination!.lat,
            _destination!.lng,
          );
          
          _distanceToDestination = distanceInMeters;

          // Check if we reached the entry point
          if (_targetEntryPoint != null) {
            double distanceToEntry = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              _targetEntryPoint!.latitude,
              _targetEntryPoint!.longitude,
            );

            if (distanceToEntry <= AppConstants.entryPointRadius && !_isIndoor) {
              _triggerIndoorArrival();
            }
          }

          // TODO: Update current instruction based on route progress
        }
        notifyListeners();
      }
    });
  }

  void _triggerIndoorArrival() {
    _currentInstruction = 'You have arrived at ${_targetEntryPoint?.label ?? 'the entrance'}. Switch to indoor navigation.';
    switchToIndoorNavigation();
  }

  void switchToIndoorNavigation() {
    _isIndoor = true;
    _positionStreamSubscription?.cancel();
    notifyListeners();
    // Indoor logic will be handled by IndoorNavigationScreen
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
