import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/floor_model.dart';
import '../../models/route_model.dart';
import '../../models/location_model.dart';
import '../../services/firestore_service.dart';
import '../../core/constants/colors.dart';
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
  RouteModel? _currentRoute;
  LocationModel? _destination;
  
  bool _showInstructionPanel = true;
  String _currentInstruction = 'Loading route...';
  
  // To handle the two-phase routing if destination is not on floor 0
  bool _isNavigatingToStairs = false;

  @override
  void initState() {
    super.initState();
    _currentFloor = widget.floor;
    _loadNavigationData();
  }

  Future<void> _loadNavigationData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Fetch destination details to know its floor and room number
      if (widget.destinationLocationId != null) {
        _destination = await _firestoreService.getLocation(widget.destinationLocationId!);
      }

      // 2. Fetch Floor Map Data
      _currentFloorData = await _firestoreService.getFloorMap(widget.buildingId, _currentFloor);
      
      // 3. Determine Routing Phase
      await _calculateRoute();
      
    } catch (e) {
      debugPrint('Error loading indoor nav data: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _calculateRoute() async {
    _currentRoute = null; // reset
    if (_destination == null) {
       _currentInstruction = 'Destination not found.';
       return;
    }
    
    final int destFloor = _destination?.floor ?? 0;
    
    // For this example, we mock the route payload. Real app would query a 'routes' collection.
    
    if (_currentFloor == 0 && destFloor > 0) {
       // Phase 1: Go to Stairs (Current floor is 0, destination is higher)
       _isNavigatingToStairs = true;
       _currentInstruction = 'Follow the path to reach stairs\nand change floor to Floor $destFloor';
       
       final route = await _firestoreService.getRoute(
         widget.buildingId, 0, widget.entryPointId, 'stairs'
       );
       _currentRoute = route ?? _mockRouteToStairs(); 
       
    } else if (_currentFloor == destFloor && destFloor > 0) {
       // Phase 2: On Destination Floor
       _isNavigatingToStairs = false;
       final toLocation = _destination!.roomNumber ?? _destination!.name;
       _currentInstruction = 'Follow the path\nto Destination';
       
       final route = await _firestoreService.getRoute(
         widget.buildingId, destFloor, 'stairs', toLocation
       );
       _currentRoute = route ?? _mockRouteToRoom('stairs', toLocation);
       
    } else if (destFloor == 0) {
       // Phase 3: Destination is on Floor 0
       _isNavigatingToStairs = false;
       final toLocation = _destination!.roomNumber ?? _destination!.name;
       _currentInstruction = 'Follow the path\nto Destination';
       
       final route = await _firestoreService.getRoute(
         widget.buildingId, 0, widget.entryPointId, toLocation
       );
       _currentRoute = route ?? _mockRouteToRoom(widget.entryPointId, toLocation);
       
    } else {
       _currentInstruction = 'Floor mismatch.';
    }
  }
  
  void _onReachedWaypoint() {
      if (_isNavigatingToStairs) {
         // Show confirmation, then switch floor
         _showStairDialog();
      } else {
         // Arrived at destination
         _showArrivalDialog();
      }
  }

  void _showStairDialog() {
       showDialog(
         context: context,
         barrierDismissible: false,
         builder: (context) => AlertDialog(
            title: const Text('Reached Stairs'),
            content: Text('Please confirm if you have reached target Floor ${_destination?.floor}.'),
            actions: [
               TextButton(
                  onPressed: () {
                     Navigator.pop(context);
                     _switchFloor(_destination?.floor ?? 0);
                  },
                  child: const Text('Confirm target floor')
               )
            ]
         )
       );
  }

  void _showArrivalDialog() {
       showDialog(
         context: context,
         barrierDismissible: false,
         builder: (context) => AlertDialog(
            title: const Text('Completed Navigation'),
            content: Text('You have reached ${_destination?.name}.'),
            actions: [
               TextButton(
                  onPressed: () {
                     Provider.of<NavigationProvider>(context, listen: false).stopNavigation();
                     Navigator.pop(context); // close dialog
                     Navigator.pop(context); // close nav screen
                  },
                  child: const Text('Finish Navigation')
               )
            ]
         )
       );
  }

  void _switchFloor(int newFloor) {
      setState(() {
          _currentFloor = newFloor;
      });
      _loadNavigationData();
  }

  @override
  Widget build(BuildContext context) {
    String floorName = _currentFloor == 0 ? 'Ground' : 'Floor $_currentFloor';
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background like mockup
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // Interactive Floor Map Card
                Positioned(
                  top: 100,
                  left: 16,
                  right: 16,
                  bottom: 180, // Space for bottom controls
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: _buildInteractiveMap(),
                    ),
                  ),
                ),
                
                // Header Pane
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: _buildHeaderWidget(floorName),
                ),
                  
                // Bottom Controls Pane
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

  Widget _buildInteractiveMap() {
    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(100),
      minScale: 0.5,
      maxScale: 3.0,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. The Floor Map Image/SVG
            if (_currentFloorData?.svgMapData != null)
               SvgPicture.string(_currentFloorData!.svgMapData!, width: 300, height: 400)
            else if (_currentFloorData?.svgMapUrl != null)
               SvgPicture.network(_currentFloorData!.svgMapUrl!, width: 300, height: 400)
            else if (_currentFloorData?.mapImageUrl != null)
               Image.network(_currentFloorData!.mapImageUrl!, width: 300, height: 400, fit: BoxFit.contain)
            else 
               Container(
                  width: 300, height: 400,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                  child: Center(child: Text('Map for Floor $_currentFloor not available')),
               ),

            // 2. POIs Overlay
            if (_currentFloorData != null && _currentFloorData!.pois.isNotEmpty)
              Positioned.fill(
                child: CustomPaint(
                  size: const Size(300, 400),
                  painter: _POIPainter(pois: _currentFloorData!.pois),
                ),
              ),

            // 3. The Route Overlay
            if (_currentRoute != null)
               CustomPaint(
                  size: const Size(300, 400), // Should match map dimensions
                  painter: _RoutePainter(_currentRoute!.points),
               ),
          ],
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
         child: Row(
            children: [
               GestureDetector(
                onTap: () {
                   Provider.of<NavigationProvider>(context, listen: false).stopNavigation();
                   Navigator.pop(context);
                },
                 child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                       color: Colors.black,
                       borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.turn_left, color: Colors.white),
                 ),
               ),
               const SizedBox(width: 16),
               Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$floorName Floor ${widget.buildingName}',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                         _currentInstruction.replaceAll('\n', ' '),
                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                         maxLines: 2,
                         overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )
               ),
               IconButton(
                 style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFEEEEEE),
                    shape: const CircleBorder(),
                 ),
                 icon: const Icon(Icons.close, color: Colors.black),
                 onPressed: () {
                    Provider.of<NavigationProvider>(context, listen: false).stopNavigation();
                    Navigator.pop(context);
                 },
               ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _isNavigatingToStairs ? '13m ahead' : '35m ahead',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Flow Blue line',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isNavigatingToStairs ? 'Floor Change\nNeeded' : 'To reach\nDestination.',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _onReachedWaypoint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Confirm', style: TextStyle(fontSize: 16)),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Exit Navigation', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- MOCK DATA GENERATORS FOR TESTING ----
  RouteModel _mockRouteToStairs() {
     return RouteModel(
        id: 'r_stairs',
        fromLocation: widget.entryPointId,
        toLocation: 'stairs',
        points: const [
           RoutePoint(x: 50, y: 350),
           RoutePoint(x: 100, y: 350),
           RoutePoint(x: 100, y: 200),
           RoutePoint(x: 250, y: 200),
        ]
     );
  }

  RouteModel _mockRouteToRoom(String from, String to) {
     return RouteModel(
        id: 'r_room',
        fromLocation: from,
        toLocation: to,
        points: const [
           RoutePoint(x: 250, y: 200), // Stairs position
           RoutePoint(x: 250, y: 100),
           RoutePoint(x: 150, y: 100),
           RoutePoint(x: 150, y: 50),
        ]
     );
  }
}

class _RoutePainter extends CustomPainter {
  final List<RoutePoint> points;
  _RoutePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points.first.x, points.first.y);
    for (int i = 1; i < points.length; i++) {
       path.lineTo(points[i].x, points[i].y);
    }

    canvas.drawPath(path, paint);

    // Draw End Marker
    final markerPaint = Paint()..color = Colors.red..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(points.last.x, points.last.y), 6.0, markerPaint);
    
    // Draw Start Marker
    final startPaint = Paint()..color = Colors.green..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(points.first.x, points.first.y), 6.0, startPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _POIPainter extends CustomPainter {
  final List<POI> pois;

  _POIPainter({required this.pois});

  @override
  void paint(Canvas canvas, Size size) {
    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const textStyle = TextStyle(
      color: Colors.black,
      fontSize: 8,
      fontWeight: FontWeight.bold,
      backgroundColor: Colors.white70,
    );

    for (final poi in pois) {
      final offset = Offset(poi.x * size.width, poi.y * size.height);
      
      // Draw point
      canvas.drawCircle(offset, 4.0, pointPaint);
      canvas.drawCircle(offset, 4.0, borderPaint);

      // Draw label
      final textPainter = TextPainter(
        text: TextSpan(text: poi.name, style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      // Position label slightly above the point
      textPainter.paint(
        canvas,
        Offset(offset.dx - (textPainter.width / 2), offset.dy - 12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
