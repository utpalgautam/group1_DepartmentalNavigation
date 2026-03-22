import 'dart:math' as math;
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

  // View toggles
  bool _is3DMode = true;
  bool _showLabels = false;

  // 3D Map interactive state
  double _scale = 1.0;
  double _baseScale = 1.0;
  double _panX = 0.0;
  double _panY = 0.0;
  double _rotationZ = 0.05;
  double _baseRotation = 0.05;
  final double _tiltAngle = -0.9;

  int _routeDistanceMeters = 0;

  @override
  void initState() {
    super.initState();
    _loadDataAndComputeRoute();
  }

  Future<void> _loadDataAndComputeRoute() async {
    try {
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

      _calculateRouteDistance();

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

  void _calculateRouteDistance() {
    if (_currentPath.isEmpty) {
      _routeDistanceMeters = 0;
      return;
    }

    double totalWeight = 0.0;
    for (int i = 0; i < _currentPath.length - 1; i++) {
      final nodeA = _currentPath[i];
      final nodeB = _currentPath[i + 1];

      try {
        final edge = widget.graph.edges.firstWhere((e) =>
            (e.from == nodeA.id && e.to == nodeB.id) ||
            (e.from == nodeB.id && e.to == nodeA.id));
        totalWeight += edge.weight;
      } catch (_) {}
    }

    _routeDistanceMeters = (totalWeight / 40).round();
  }

  String _getProcessedSvg() {
    if (_floorData == null ||
        (_floorData!.svgMapData == null && _floorData!.svgMapUrl == null)) {
      return '';
    }

    String svg = _floorData!.svgMapData ?? '';
    if (svg.isEmpty) return '';

    final vb = widget.graph.viewBox ?? [0.0, 0.0, 800.0, 600.0];
    final double mapWidth = (vb.length > 2 && vb[2] > 0) ? vb[2] : 800.0;
    final double mapHeight = (vb.length > 3 && vb[3] > 0) ? vb[3] : 600.0;
    String viewBoxStr =
        '${vb.isNotEmpty ? vb[0] : 0.0} ${vb.length > 1 ? vb[1] : 0.0} $mapWidth $mapHeight';

    svg = svg.replaceFirst(RegExp(r'<svg[^>]*>'),
        '<svg viewBox="$viewBoxStr" preserveAspectRatio="xMidYMid meet" xmlns="http://www.w3.org/2000/svg">');

    StringBuffer overlays = StringBuffer();

    if (_currentPath.isNotEmpty) {
      String points = _currentPath.map((p) => '${p.x},${p.y}').join(' ');

      overlays.write(
          '<polyline points="$points" stroke="#bfdbfe" stroke-width="24" fill="none" stroke-linecap="round" stroke-linejoin="round" />');

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

            overlays.write(
                '<polyline points="$x1,$y1 $cx,$cy $x2,$y2" stroke="#2563eb" stroke-width="4" fill="none" stroke-linecap="round" stroke-linejoin="round" />');
          }
        }
      }

      // Start Marker
      final start = _currentPath.first;
      overlays.write(
          '<circle cx="${start.x}" cy="${start.y}" r="16" fill="#bfdbfe" fill-opacity="0.8" />');
      overlays.write(
          '<circle cx="${start.x}" cy="${start.y}" r="8" fill="#2563eb" />');
    }

    return svg.replaceFirst('</svg>', '${overlays.toString()}</svg>');
  }

  /// 2D label overlays — placed inside Transform (correct in 2D mode)
  List<Widget> _build2DLabelOverlays(
      double mapWidth, double mapHeight, double w, double h) {
    final labelNodes = widget.graph.nodes
        .where((n) => n.type != 'hallway' && n.label.isNotEmpty)
        .toList();
    return labelNodes.map((node) {
      final double left = (node.x / mapWidth) * w;
      final double top = (node.y / mapHeight) * h;
      return Positioned(
        left: left - 3,
        top: top - 3,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: _nodeColor(node.type),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1)),
                ],
              ),
            ),
            const SizedBox(width: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.88),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black12, width: 0.5),
              ),
              child: Text(
                node.label,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// 3D labels — placed OUTSIDE the Transform in screen space.
  List<Widget> _build3DScreenSpaceLabels({
    required double screenW,
    required double screenH,
    required double mapWidth,
    required double mapHeight,
    required double displayW,
    required double displayH,
    required double mapLeft,
    required double mapTop,
    required Matrix4 transform,
  }) {
    final labelNodes = widget.graph.nodes
        .where((n) => n.type != 'hallway' && n.label.isNotEmpty)
        .toList();

    final cx = screenW / 2.0;
    final cy = screenH / 2.0;
    final s = transform.storage; // column-major Float64List

    return labelNodes.map((node) {
      final double nx = mapLeft + (node.x / mapWidth) * displayW;
      final double ny = mapTop + (node.y / mapHeight) * displayH;
      final double px = nx - cx;
      final double py = ny - cy;
      // Apply matrix (z=0, w=1) — column-major
      final double xp = s[0] * px + s[4] * py + s[12];
      final double yp = s[1] * px + s[5] * py + s[13];
      final double wp = s[3] * px + s[7] * py + s[15];
      final double sx = (wp == 0 ? xp : xp / wp) + cx;
      final double sy = (wp == 0 ? yp : yp / wp) + cy;

      const double boxH = 20.0;
      const double stemH = 5.0;
      const double dotR = 3.5;

      return Stack(
        children: [
          // Blue node dot at exact projected position
          Positioned(
            left: sx - dotR,
            top: sy - dotR,
            child: Container(
              width: dotR * 2,
              height: dotR * 2,
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Comment box centered over sx via FractionalTranslation
          Positioned(
            left: sx,
            top: sy - boxH - stemH,
            child: FractionalTranslation(
              translation: const Offset(-0.5, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomPaint(
                    painter: _DashedRoundedBorderPainter(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.14),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        node.label,
                        style: const TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  CustomPaint(
                    size: const Size(7, stemH),
                    painter: _TrianglePainter(),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }).toList();
  }

  Color _nodeColor(String type) {
    switch (type) {
      case 'room':
        return Colors.blue.shade600;
      case 'stairs':
        return Colors.orange.shade600;
      case 'entrance':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
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
                  Positioned.fill(
                    child: _buildInteractiveMap(),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: _buildHeaderWidget(floorName),
                      ),
                    ),
                  ),
                  // Toggle buttons: top-right, below the header
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 110,
                    right: 16,
                    child: _buildToggleButtons(),
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

  Widget _buildToggleButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 3D / 2D Toggle
        GestureDetector(
          onTap: () {
            setState(() {
              _is3DMode = !_is3DMode;
              if (!_is3DMode) {
                _rotationZ = 0.0;
                _baseRotation = 0.0;
              } else {
                _rotationZ = 0.05;
                _baseRotation = 0.05;
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _is3DMode ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: _is3DMode ? Colors.black : Colors.black12,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _is3DMode ? Icons.view_in_ar_rounded : Icons.map_outlined,
                  size: 14,
                  color: _is3DMode ? Colors.white : Colors.black87,
                ),
                const SizedBox(width: 4),
                Text(
                  _is3DMode ? '3D' : '2D',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _is3DMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Labels Toggle
        GestureDetector(
          onTap: () => setState(() => _showLabels = !_showLabels),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _showLabels ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: _showLabels ? Colors.black : Colors.black12,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.label_rounded,
                  size: 14,
                  color: _showLabels ? Colors.white : Colors.black87,
                ),
                const SizedBox(width: 4),
                Text(
                  'Labels',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _showLabels ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveMap() {
    if (_errorMessage.isNotEmpty && _floorData == null) {
      return Center(child: Text(_errorMessage));
    }
    final processedSvg = _getProcessedSvg();
    if (processedSvg.isEmpty) {
      return Center(
          child: Text('Map for Floor ${widget.floorNo} not available'));
    }

    final vb = widget.graph.viewBox ?? [0.0, 0.0, 800.0, 600.0];
    final double mapWidth = (vb.length > 2 && vb[2] > 0) ? vb[2] : 800.0;
    final double mapHeight = (vb.length > 3 && vb[3] > 0) ? vb[3] : 600.0;

    return LayoutBuilder(builder: (context, outerConstraints) {
      final double screenW = outerConstraints.maxWidth;
      final double screenH = outerConstraints.maxHeight;

      final Matrix4 transform = Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..translate(_panX, _panY);
      if (_is3DMode) {
        transform
          ..rotateX(_tiltAngle)
          ..scale(_scale)
          ..rotateZ(_rotationZ);
      } else {
        transform
          ..scale(_scale)
          ..rotateZ(_rotationZ);
      }

      final double ratio = mapWidth / mapHeight;
      final double displayW, displayH, mapLeft, mapTop;
      if (screenW / screenH >= ratio) {
        displayH = screenH;
        displayW = displayH * ratio;
      } else {
        displayW = screenW;
        displayH = displayW / ratio;
      }
      mapLeft = (screenW - displayW) / 2.0;
      mapTop = (screenH - displayH) / 2.0;

      return GestureDetector(
        onScaleStart: (details) {
          _baseScale = _scale;
          _baseRotation = _rotationZ;
        },
        onScaleUpdate: (details) {
          setState(() {
            _panX += details.focalPointDelta.dx;
            _panY += details.focalPointDelta.dy;
            _scale = (_baseScale * details.scale).clamp(0.5, 6.0);
            _rotationZ = _baseRotation + details.rotation;
          });
        },
        child: ClipRRect(
          child: Container(
            color: const Color(0xFFF5F5F5),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Transform(
                    alignment: Alignment.center,
                    transform: transform,
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
                                    processedSvg, fit: BoxFit.contain),
                                if (_currentPath.isNotEmpty)
                                  Positioned(
                                    left: (_currentPath.last.x / mapWidth) *
                                            w -
                                        24,
                                    top: (_currentPath.last.y / mapHeight) *
                                            h -
                                        48,
                                    child: Transform(
                                      alignment: Alignment.bottomCenter,
                                      transform: Matrix4.identity()
                                        ..rotateZ(-_rotationZ)
                                        ..rotateX(
                                            _is3DMode ? -_tiltAngle : 0),
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.black,
                                        size: 48,
                                      ),
                                    ),
                                  ),
                                // 2D labels inside Transform
                                if (_showLabels && !_is3DMode)
                                  ..._build2DLabelOverlays(
                                      mapWidth, mapHeight, w, h),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                // 3D screen-space labels outside Transform
                if (_showLabels && _is3DMode)
                  ..._build3DScreenSpaceLabels(
                    screenW: screenW,
                    screenH: screenH,
                    mapWidth: mapWidth,
                    mapHeight: mapHeight,
                    displayW: displayW,
                    displayH: displayH,
                    mapLeft: mapLeft,
                    mapTop: mapTop,
                    transform: transform,
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeaderWidget(String floorName) {
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
                  '$floorName ${widget.buildingModel.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _errorMessage.isNotEmpty
                      ? _errorMessage
                      : 'Follow the route to destination',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        _errorMessage.isNotEmpty ? Colors.red : Colors.black,
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
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControlsWidget() {
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Flow Blue line',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    'Target nearby',
                    style: TextStyle(
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
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Confirm Reach',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Exit Navigation',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the small downward-pointing triangle (comment box stem)
class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) => false;
}

/// Custom painter that draws a dashed rounded-rectangle border
class _DashedRoundedBorderPainter extends CustomPainter {
  final Color color;
  final double dash;
  final double gap;
  final double radius;
  final double strokeWidth;

  _DashedRoundedBorderPainter({
    this.color = Colors.black38,
    this.dash = 2.5,
    this.gap = 2.5,
    this.radius = 6.0,
    this.strokeWidth = 0.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      bool drawing = true;
      while (distance < metric.length) {
        final segEnd = (distance + (drawing ? dash : gap))
            .clamp(0.0, metric.length);
        if (drawing) {
          canvas.drawPath(
              metric.extractPath(distance, segEnd), paint);
        }
        distance = segEnd;
        drawing = !drawing;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRoundedBorderPainter old) => false;
}
