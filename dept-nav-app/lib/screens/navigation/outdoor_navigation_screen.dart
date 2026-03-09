import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
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
  State<OutdoorNavigationScreen> createState() => _OutdoorNavigationScreenState();
}

class _OutdoorNavigationScreenState extends State<OutdoorNavigationScreen> {
  MaplibreMapController? _mapController;
  bool _isMapReady = false;
  bool _showTurnByTurn = false;
  bool _isTransitioningToIndoor = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navProvider, child) {
        // Listen for arrival logic
        if (navProvider.isIndoor && navProvider.isNavigating && !_isTransitioningToIndoor) {
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
            initialCameraPosition: const CameraPosition(
              target: LatLng(AppConstants.campusLat, AppConstants.campusLng),
              zoom: AppConstants.defaultMapZoom,
            ),
            styleString: MapStyle.osm,
            myLocationEnabled: _isMapReady, // Only enable if map is ready, and we can turn it off
            myLocationRenderMode: _isMapReady ? MyLocationRenderMode.compass : MyLocationRenderMode.normal,
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
                            widget.destinationName ?? widget.targetBuilding?.name ?? 'Selected Location',
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
                instruction: navProvider.currentInstruction ?? 'Head to destination',
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
              instruction: widget.targetBuilding?.name ?? 'Destination',
              distance: navProvider.currentRoute != null
                    ? '${navProvider.currentRoute!.distance.toStringAsFixed(0)}m'
                    : '...',
              time: navProvider.currentRoute != null
                    ? '${(navProvider.currentRoute!.time / 60000).ceil()} min'
                    : '...',
              onStartNavigation: () => _startNavigation(navProvider),
              onStopNavigation: () => _stopNavigation(navProvider),
              onConfirmArrival: () => navProvider.switchToIndoorNavigation(),
            ),
          ),
          
          // Arrival Dialog
          if (navProvider.isIndoor)
            _buildArrivalOverlay(),
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
                     floor: widget.targetBuilding!.totalFloors > 1 ? 0 : 0, // start at floor 0
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
               child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     const Icon(Icons.check_circle, color: Colors.green, size: 64),
                     const SizedBox(height: 16),
                     Text(
                        'Arrived at ${widget.targetBuilding?.name ?? 'Destination'}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                     ),
                     const SizedBox(height: 8),
                     const Text('Switching to Indoor Navigation...'),
                     const SizedBox(height: 24),
                     ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        onPressed: () => _navigateToIndoorScreen(context),
                        child: const Text('Continue Indoors'),
                     ),
                  ]
               )
            )
         )
      );
  }

  void _onMapCreated(MaplibreMapController controller) {
    _mapController = controller;
  }

  void _onStyleLoaded() {
    setState(() {
      _isMapReady = true;
    });
    
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
    if (widget.destLat != null && widget.destLng != null && !provider.isNavigating) {
      provider.previewRoute(
        NavigationPoint(lat: widget.destLat!, lng: widget.destLng!),
        targetBuilding: widget.targetBuilding,
        entryPoint: widget.targetEntryPoint,
      );
    }
    
    provider.addListener(_onProviderUpdated);
    
    // Kick initial update in case provider already has a route
    _onProviderUpdated();
  }

  void _onProviderUpdated() {
     final provider = Provider.of<NavigationProvider>(context, listen: false);
     if (provider.currentRoute != null && _isMapReady) {
         _drawRoute(provider.currentRoute!.coordinates);
     }
     
     // Optionally follow camera
     if (provider.isNavigating && provider.currentPosition != null && _isMapReady) {
         _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
               CameraPosition(
                  target: LatLng(provider.currentPosition!.latitude, provider.currentPosition!.longitude),
                  zoom: 18,
                  bearing: provider.currentPosition!.heading,
                  tilt: 45,
               )
            )
         );
     }
  }

  void _drawRoute(List<LatLng> points) async {
      if (_mapController == null || points.isEmpty) return;
      
      try {
          await _mapController!.clearLines();
          await _mapController!.addLine(
              LineOptions(
                  geometry: points,
                  lineColor: '#2196F3',
                  lineWidth: 6.0,
                  lineOpacity: 0.8,
              )
          );
          
          // Fit bounds to show entire route
          LatLngBounds bounds = _getBounds(points);
          _mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, top: 150, left: 50, right: 50, bottom: 250),
          );
      } catch (e) {
          debugPrint('Error drawing route on Maplibre: $e');
      }
  }

  LatLngBounds _getBounds(List<LatLng> points) {
    if (points.isEmpty) { // Fallback to campus bounds 
        return LatLngBounds(southwest: const LatLng(11.3190, 76.0190), northeast: const LatLng(11.3210, 76.0210));
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
      if (_mapController != null && _mapController!.symbols != null) {
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
  }

  void _addDestinationMarker() async {
    if (_mapController == null || widget.destLat == null || widget.destLng == null) return;
    
    if (_mapController != null && _mapController!.symbols != null) {
      try {
        await _mapController!.addSymbol(
          SymbolOptions(
            geometry: LatLng(widget.targetEntryPoint?.latitude ?? widget.destLat!, widget.targetEntryPoint?.longitude ?? widget.destLng!),
            iconImage: 'assets/icons/destination_marker.png',
            iconSize: 0.6,
          ),
        );
      } catch (e) {
        debugPrint('Error adding destination marker: $e');
      }
    }
  }

  void _startNavigation(NavigationProvider provider) {
    if (provider.currentRoute != null) {
      provider.startOutdoorNavigation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to calculate route. Please try again.')),
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
  static const String osm = '''
  {
    "version": 8,
    "sources": {
      "osm": {
        "type": "raster",
        "tiles": ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],
        "tileSize": 256,
        "attribution": "© OpenStreetMap contributors"
      }
    },
    "layers": [
      {
        "id": "osm",
        "type": "raster",
        "source": "osm",
        "minzoom": 0,
        "maxzoom": 19
      }
    ]
  }
  ''';
}