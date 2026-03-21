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
  bool _isDebugMode = false;

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

    // Add Route
    if (_currentPath.isNotEmpty) {
      String points = _currentPath.map((p) => '${p.x},${p.y}').join(' ');
      overlays.write('<polyline points="$points" stroke="blue" stroke-width="4" fill="none" stroke-linecap="round" stroke-linejoin="round" />');
      
      // Add Destination Marker in SVG
      final dest = _currentPath.last;
      overlays.write('<circle cx="${dest.x}" cy="${dest.y}" r="8" fill="red" />');

      // Add Start (User) Marker in SVG
      final start = _currentPath.first;
      overlays.write('<circle cx="${start.x}" cy="${start.y}" r="8" fill="green" />');
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
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _buildMapView(),
                  ),
                  _buildBottomPanel(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    String floorName = _currentFloor == 0 ? 'Ground' : 'Floor $_currentFloor';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.buildingName,
                    style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  Text(
                    floorName,
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 22),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isDebugMode ? Icons.bug_report : Icons.bug_report_outlined,
                      color: _isDebugMode ? Colors.red : Colors.grey,
                    ),
                    onPressed: () => setState(() => _isDebugMode = !_isDebugMode),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.close, color: Colors.black, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isDebugMode && _errorMessage != null ? _errorMessage! : _currentInstruction,
            style: TextStyle(
                color: _isDebugMode && _errorMessage != null ? Colors.red : Colors.black87,
                fontSize: 15,
                fontWeight: _isDebugMode && _errorMessage != null ? FontWeight.bold : FontWeight.normal),
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
    final double vbWidth = (vb.length > 2 && vb[2] > 0) ? vb[2] : 800.0;
    final double vbHeight = (vb.length > 3 && vb[3] > 0) ? vb[3] : 600.0;

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5.0,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: AspectRatio(
            aspectRatio: vbWidth / vbHeight,
            child: SvgPicture.string(
              processedSvg,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.directions_walk, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isNavigatingToStairs ? 'Phase 1' : 'Final Phase',
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    Text(
                      _isNavigatingToStairs
                          ? 'Navigate to Stairs'
                          : 'Navigate to Destination',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onReachedWaypoint,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Confirm Reached',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
