import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/building_model.dart';
import '../../models/floor_model.dart';
import '../../services/astar_service.dart';
import '../../services/firestore_service.dart';

class IndoorRouteViewScreen extends StatefulWidget {
  final BuildingModel buildingModel;
  final int floorNo;
  final IndoorGraph graph;
  final GraphNode startNode;
  final GraphNode endNode;

  const IndoorRouteViewScreen({
    super.key,
    required this.buildingModel,
    required this.floorNo,
    required this.graph,
    required this.startNode,
    required this.endNode,
  });

  @override
  State<IndoorRouteViewScreen> createState() => _IndoorRouteViewScreenState();
}

class _IndoorRouteViewScreenState extends State<IndoorRouteViewScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  FloorModel? _floorData;
  List<GraphNode> _currentPath = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDataAndComputeRoute();
  }

  Future<void> _loadDataAndComputeRoute() async {
    try {
      // 1. Compute Path immediately since we already have the graph
      final path = AStarService.findPath(
          widget.graph, widget.startNode.id, widget.endNode.id);

      if (path.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'No route found between selected nodes.';
            _isLoading = false;
          });
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(_errorMessage)));
        }
        return;
      }
      _currentPath = path;
      debugPrint(
          'A* Computed Route nodes: ${_currentPath.map((n) => n.id).toList()}');

      // 2. Fetch Floor Map Data for rendering SVG
      final floorData = await _firestoreService.getFloorMap(
          widget.buildingModel.id, widget.floorNo);

      if (mounted) {
        setState(() {
          _floorData = floorData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading floor map: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load floor map data.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String floorName =
        widget.floorNo == 0 ? 'Ground Floor' : 'Floor ${widget.floorNo}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned(
                    top: 100,
                    left: 16,
                    right: 16,
                    bottom: 120,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10)
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: _buildInteractiveMap(),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: _buildHeaderWidget(floorName),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomControlsWidget(),
                  )
                ],
              ),
            ),
    );
  }

  String _getProcessedSvg() {
    if (_floorData == null || (_floorData!.svgMapData == null && _floorData!.svgMapUrl == null)) {
      return '';
    }

    String svg = _floorData!.svgMapData ?? '';
    if (svg.isEmpty) return '';

    final vb = widget.graph.viewBox ?? [0.0, 0.0, 800.0, 600.0];
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
      
      // End Marker
      final dest = _currentPath.last;
      overlays.write('<circle cx="${dest.x}" cy="${dest.y}" r="8" fill="red" />');

      // Start Marker
      final start = _currentPath.first;
      overlays.write('<circle cx="${start.x}" cy="${start.y}" r="8" fill="green" />');
    }

    // Inject before closing svg tag
    return svg.replaceFirst('</svg>', '${overlays.toString()}</svg>');
  }

  Widget _buildInteractiveMap() {
    if (_errorMessage.isNotEmpty && _floorData == null) {
      return Center(child: Text(_errorMessage));
    }

    final processedSvg = _getProcessedSvg();
    debugPrint('Processed SVG length: ${processedSvg.length}');
    if (processedSvg.length < 500) {
      debugPrint('Processed SVG content: $processedSvg');
    } else {
      debugPrint('Processed SVG start: ${processedSvg.substring(0, 200)}');
      debugPrint('Processed SVG end: ${processedSvg.substring(processedSvg.length - 200)}');
    }
    if (processedSvg.isEmpty) {
      return Center(
        child: Text('Map for Floor ${widget.floorNo} not available'),
      );
    }

    final vb = widget.graph.viewBox ?? [0.0, 0.0, 800.0, 600.0];
    final double mapWidth = (vb.length > 2 && vb[2] > 0) ? vb[2] : 800.0;
    final double mapHeight = (vb.length > 3 && vb[3] > 0) ? vb[3] : 600.0;

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5.0,
      child: Center(
        child: AspectRatio(
          aspectRatio: mapWidth / mapHeight,
          child: SvgPicture.string(
            processedSvg,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderWidget(String floorName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$floorName - ${widget.buildingModel.name}',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const Text(
                      'Follow the blue route.',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_currentPath.isEmpty && _errorMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildBottomControlsWidget() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: const Text('Exit Navigation', style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
