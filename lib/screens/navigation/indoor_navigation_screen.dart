import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/floor_model.dart';
import '../../models/location_model.dart';
import '../../services/firestore_service.dart';
import '../../services/astar_service.dart';
import 'package:provider/provider.dart';
import '../../providers/navigation_provider.dart';

class IndoorNavigationScreen extends StatefulWidget {
  final String buildingId;
  final String buildingName;
  final int floor;
  final String entryPointId;
  final String? destinationLocationId;

  const IndoorNavigationScreen({
    super.key,
    required this.buildingId,
    this.buildingName = 'Building',
    required this.floor,
    required this.entryPointId,
    this.destinationLocationId,
  });

  @override
  State<IndoorNavigationScreen> createState() => _IndoorNavigationScreenState();
}

class _IndoorNavigationScreenState extends State<IndoorNavigationScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  int _currentFloor = 0;
  FloorModel? _currentFloorData;
  IndoorGraph? _currentGraph;
  List<GraphNode> _currentPath = [];
  LocationModel? _destination;

  String _currentInstruction = 'Loading route...';
  String? _errorMessage;

  bool _isNavigatingToStairs = false;
  final bool _isDebugMode = false;

  // Map interactive state
  double _scale = 1.0;
  double _baseScale = 1.0;
  double _panX = 0.0;
  double _panY = 0.0;
  double _rotationZ = 0.05; // Initial slight rotation 
  double _baseRotation = 0.05;
  final double _tiltAngle = -0.9; // Negative to tilt top away, bottom closer

  int _routeDistanceMeters = 0;

  @override
  void initState() {
    super.initState();
    _currentFloor = widget.floor;
    _loadNavigationData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadNavigationData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.destinationLocationId != null) {
        _destination =
            await _firestoreService.getLocation(widget.destinationLocationId!);
      }

      _currentFloorData =
          await _firestoreService.getFloorMap(widget.buildingId, _currentFloor);

      _currentGraph = await _firestoreService.getIndoorGraph(
          widget.buildingId, _currentFloor);

      if (_currentGraph == null) {
        _errorMessage = 'Indoor navigation unavailable for this floor.';
        _currentInstruction = _errorMessage!;
      } else {
        await _calculateRoute();
      }
    } catch (e, stack) {
      debugPrint('Error loading indoor nav data: $e');
      debugPrint('Stack trace: $stack');
      _errorMessage = 'Failed to load navigation data: $e';
      _currentInstruction = 'Failed to load navigation data.';
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _calculateRoute() async {
    _currentPath = [];
    if (_destination == null) {
      _currentInstruction = 'Destination not found.';
      return;
    }

    if (_currentGraph == null) {
      _currentInstruction = 'Indoor navigation unavailable for this floor.';
      return;
    }

    final int targetFloor = _destination?.floor ?? 0;
    final IndoorGraph graph = _currentGraph!;
    final String entryLabel = widget.entryPointId; 
    final String roomLabel = _destination!.roomNumber ?? _destination!.name;

    if (_currentFloor != targetFloor) {
      // Phase 1: Entry -> Stairs
      _isNavigatingToStairs = true;
      
      // The user's snippet: const path = runAStar(graph, entryLabel, "Stairs");
      _currentPath = AStarService.findPath(graph, entryLabel, "Stairs");
      
      if (_currentPath.isEmpty) {
        // Fallback for Entry if label matching fails
        _currentPath = AStarService.findPath(graph, "Stairs", "Stairs"); // This is just to check if Stairs exist
        if (_currentPath.isEmpty) {
           _currentInstruction = 'Route to stairs not found.';
        } else {
           _currentInstruction = 'Route from $entryLabel to stairs not found.';
        }
      } else {
        _currentInstruction = 'Follow route to stairs and change floor to Floor $targetFloor';
      }
    } else {
      // Phase 2: Stairs -> Room (or Entry -> Room if no stairs needed)
      _isNavigatingToStairs = false;

      // If we are on the target floor, we might have started from stairs or from entry
      // If we just came from stairs, start node should be "Stairs"
      // If we are starting from entry on the same floor, start node is entryLabel
      // Let's check if "Stairs" is a better starting point if we are in Phase 2 after a floor change
      
      String startLabel = entryLabel;
      // Heuristic to check if we should start from stairs: if we are on target floor and it's not the original floor
      if (_currentFloor != widget.floor) {
        startLabel = "Stairs";
      }

      _currentPath = AStarService.findPath(graph, startLabel, roomLabel);
      
      if (_currentPath.isEmpty && startLabel == "Stairs") {
        // Fallback to entry label if stairs path fails (maybe entry point is on this floor)
        _currentPath = AStarService.findPath(graph, entryLabel, roomLabel);
      }

      if (_currentPath.isEmpty) {
        _currentInstruction = 'Route to $roomLabel not found.';
      } else {
        _currentInstruction = 'Follow the path to reach $roomLabel';
      }
    }

    _calculateRouteDistance();
  }

  void _calculateRouteDistance() {
    if (_currentPath.isEmpty || _currentGraph == null) {
      _routeDistanceMeters = 0;
      return;
    }

    double totalWeight = 0.0;
    for (int i = 0; i < _currentPath.length - 1; i++) {
      final nodeA = _currentPath[i];
      final nodeB = _currentPath[i + 1];
      
      try {
        final edge = _currentGraph!.edges.firstWhere(
          (e) => (e.from == nodeA.id && e.to == nodeB.id) || 
                 (e.from == nodeB.id && e.to == nodeA.id)
        );
        totalWeight += edge.weight;
      } catch (_) {}
    }

    _routeDistanceMeters = (totalWeight / 40).round();
  }


  void _onReachedWaypoint() {
    if (_isNavigatingToStairs) {
      _showStairDialog();
    } else {
      _showArrivalDialog();
    }
  }

  void _showStairDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Floor', style: TextStyle(color: Colors.white)),
        content: Text('Please go to Floor ${_destination?.floor}.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _switchFloor(_destination?.floor ?? 0);
            },
            child: const Text('I am on the new floor',
                style: TextStyle(color: Colors.blue)),
          )
        ],
      ),
    );
  }

  void _showArrivalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Destination Reached',
            style: TextStyle(color: Colors.white)),
        content: Text('You have arrived at ${_destination?.name}.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<NavigationProvider>(context, listen: false)
                  .stopNavigation();
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close nav screen
            },
            child: const Text('Finish', style: TextStyle(color: Colors.blue)),
          )
        ],
      ),
    );
  }

  void _switchFloor(int newFloor) {
    setState(() {
      _currentFloor = newFloor;
    });
    _loadNavigationData();
  }

  String _getProcessedSvg() {
    if (_currentFloorData == null || (_currentFloorData!.svgMapData == null && _currentFloorData!.svgMapUrl == null)) {
      return '';
    }

    String svg = _currentFloorData!.svgMapData ?? '';
    if (svg.isEmpty) return '';

    final vb = _currentGraph?.viewBox ?? [0.0, 0.0, 800.0, 600.0];
    final double mapWidth = (vb.length > 2 && vb[2] > 0) ? vb[2] : 800.0;
    final double mapHeight = (vb.length > 3 && vb[3] > 0) ? vb[3] : 600.0;
    String viewBoxStr = '${vb.isNotEmpty ? vb[0] : 0.0} ${vb.length > 1 ? vb[1] : 0.0} $mapWidth $mapHeight';

    // Ensure svg tag has the correct viewBox and remove width/height to let it scale in container
    svg = svg.replaceFirst(RegExp(r'<svg[^>]*>'), '<svg viewBox="$viewBoxStr" preserveAspectRatio="xMidYMid meet" xmlns="http://www.w3.org/2000/svg">');

    StringBuffer overlays = StringBuffer();

    // Add Route with arrows
    if (_currentPath.isNotEmpty) {
      String points = _currentPath.map((p) => '${p.x},${p.y}').join(' ');
      
      // Light blue base line (much thicker to match reference)
      overlays.write('<polyline points="$points" stroke="#bfdbfe" stroke-width="24" fill="none" stroke-linecap="round" stroke-linejoin="round" />');

      // Explicitly draw chevrons instead of using SVG markers safely
      double arrowSpacing = 20.0;
      double arrowSize = 8.0;

      for (int i = 0; i < _currentPath.length - 1; i++) {
        final p1 = _currentPath[i];
        final p2 = _currentPath[i + 1];
        double dx = p2.x - p1.x;
        double dy = p2.y - p1.y;
        double dist = math.sqrt(dx * dx + dy * dy);
        double angle = math.atan2(dy, dx);
        
        if (dist > arrowSpacing) {
          int count = (dist / arrowSpacing).floor();
          for (int j = 1; j <= count; j++) {
            double fraction = (j * arrowSpacing) / dist;
            double cx = p1.x + dx * fraction;
            double cy = p1.y + dy * fraction;
            
            double x1 = cx - math.cos(angle - math.pi / 6) * arrowSize;
            double y1 = cy - math.sin(angle - math.pi / 6) * arrowSize;
            double x2 = cx - math.cos(angle + math.pi / 6) * arrowSize;
            double y2 = cy - math.sin(angle + math.pi / 6) * arrowSize;
            
            overlays.write('<polyline points="$x1,$y1 $cx,$cy $x2,$y2" stroke="#2563eb" stroke-width="4" fill="none" stroke-linecap="round" stroke-linejoin="round" />');
          }
        }
      }
      
      // Destination pin is now handled as a Flutter widget overlay

      // Start Marker (Light Blue Outer Circle, Dark Blue Inner Circle)
      final start = _currentPath.first;
      overlays.write('<circle cx="${start.x}" cy="${start.y}" r="16" fill="#bfdbfe" fill-opacity="0.8" />');
      overlays.write('<circle cx="${start.x}" cy="${start.y}" r="8" fill="#2563eb" />');
    }

    // Add Debug Nodes
    if (_isDebugMode && _currentGraph != null) {
      for (var node in _currentGraph!.nodes) {
        overlays.write('<circle cx="${node.x}" cy="${node.y}" r="4" fill="red" fill-opacity="0.6" />');
      }
    }

    // Inject before closing svg tag
    return svg.replaceFirst('</svg>', '${overlays.toString()}</svg>');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : Stack(
              children: [
                Positioned.fill(
                  child: _buildMapView(),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: _buildHeader(),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomPanel(),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    String floorName = _currentFloor == 0 ? 'Ground Floor' : 'Floor $_currentFloor';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.turn_left, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$floorName ${widget.buildingName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _isDebugMode && _errorMessage != null ? _errorMessage! : _currentInstruction,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isDebugMode && _errorMessage != null ? Colors.red : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {
                Provider.of<NavigationProvider>(context, listen: false).stopNavigation();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.close, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    final processedSvg = _getProcessedSvg();
    if (processedSvg.isEmpty) {
      return Center(
        child: Text(
          'Map data missing for Floor $_currentFloor',
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }

    final vb = _currentGraph?.viewBox ?? [0.0, 0.0, 800.0, 600.0];
    final double mapWidth = (vb.length > 2 && vb[2] > 0) ? vb[2] : 800.0;
    final double mapHeight = (vb.length > 3 && vb[3] > 0) ? vb[3] : 600.0;

    return GestureDetector(
      onScaleStart: (details) {
        _baseScale = _scale;
        _baseRotation = _rotationZ;
      },
      onScaleUpdate: (details) {
        setState(() {
          // Handle Pan
          _panX += details.focalPointDelta.dx;
          _panY += details.focalPointDelta.dy;
          
          // Handle Zoom correctly with multiplier
          _scale = (_baseScale * details.scale).clamp(0.5, 6.0);
          
          // Handle Rotation
          _rotationZ = _baseRotation + details.rotation;
        });
      },
      child: ClipRRect(
        child: Container(
          color: const Color(0xFFF5F5F5),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..translate(_panX, _panY)
              ..rotateX(_tiltAngle)
              ..scale(_scale)
              ..rotateZ(_rotationZ),
            child: Center(
              child: AspectRatio(
                aspectRatio: mapWidth / mapHeight,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double w = constraints.maxWidth;
                    final double h = constraints.maxHeight;

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        SvgPicture.string(
                          processedSvg,
                          fit: BoxFit.contain,
                        ),
                        if (_currentPath.isNotEmpty)
                          Positioned(
                            left: (_currentPath.last.x / mapWidth) * w - 24, // Half of 48 size horizontally
                            top: (_currentPath.last.y / mapHeight) * h - 48, // Bottom anchors to destination
                            child: Transform(
                              alignment: Alignment.bottomCenter,
                              transform: Matrix4.identity()
                                ..rotateZ(-_rotationZ)
                                ..rotateX(-_tiltAngle),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.black,
                                size: 48,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_routeDistanceMeters}m ahead',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Flow Blue line',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    _isNavigatingToStairs
                        ? 'Floor Change Needed'
                        : 'Target nearby',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _onReachedWaypoint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Confirm Reach', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Provider.of<NavigationProvider>(context, listen: false).stopNavigation();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Exit Navigation', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
