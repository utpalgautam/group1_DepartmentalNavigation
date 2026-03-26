import 'package:flutter/material.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../home/home_screen.dart';
import '../directory/directory_screen.dart';
import '../map/offline_maps_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/firestore_service.dart';
import '../../models/building_model.dart';
import '../../models/floor_model.dart';

// Import for the future view screen
import 'indoor_route_view_screen.dart';

class IndoorNavigationSetupScreen extends StatefulWidget {
  const IndoorNavigationSetupScreen({super.key});

  @override
  State<IndoorNavigationSetupScreen> createState() =>
      _IndoorNavigationSetupScreenState();
}

class _IndoorNavigationSetupScreenState
    extends State<IndoorNavigationSetupScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoadingBuildings = true;
  List<BuildingModel> _buildings = [];
  BuildingModel? _selectedBuilding;

  List<int> _availableFloors = [];
  int? _selectedFloor;

  bool _isLoadingGraph = false;
  IndoorGraph? _currentGraph;

  List<GraphNode> _startNodes = [];
  GraphNode? _selectedStartNode;

  List<GraphNode> _endNodes = [];
  GraphNode? _selectedEndNode;

  @override
  void initState() {
    super.initState();
    debugPrint('IndoorNavigationSetupScreen: initState');
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    debugPrint('IndoorNavigationSetupScreen: _loadBuildings started');
    try {
      final buildings = await _firestoreService.getAllBuildings();
      debugPrint('IndoorNavigationSetupScreen: _loadBuildings loaded ${buildings.length} buildings');
      if (mounted) {
        setState(() {
          _buildings = buildings;
          _isLoadingBuildings = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading buildings: $e');
      if (mounted) {
        setState(() {
          _isLoadingBuildings = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load buildings.')),
        );
      }
    }
  }

  void _onBuildingChanged(BuildingModel? building) {
    if (building == null) return;
    setState(() {
      _selectedBuilding = building;
      // Extract available floors from building metadata
      _availableFloors = List.generate(building.totalFloors, (index) => index);
      _availableFloors.sort();

      _selectedFloor = null;
      _currentGraph = null;
      _selectedStartNode = null;
      _selectedEndNode = null;
      _startNodes = [];
      _endNodes = [];
    });
  }

  Future<void> _onFloorChanged(int? floorNo) async {
    if (floorNo == null || _selectedBuilding == null) return;

    setState(() {
      _selectedFloor = floorNo;
      _isLoadingGraph = true;
      _selectedStartNode = null;
      _selectedEndNode = null;
    });

    try {
      final graph = await _firestoreService.getIndoorGraph(
          _selectedBuilding!.id, floorNo);

      if (mounted) {
        setState(() {
          _currentGraph = graph;
          _isLoadingGraph = false;
          if (graph != null) {
            // Filter nodes: exclude hallway
            final filteredNodes = graph.nodes
                .where((n) => n.type.toLowerCase() != 'hallway')
                .toList();
            _startNodes = filteredNodes;
            _endNodes = filteredNodes;
          } else {
            _startNodes = [];
            _endNodes = [];
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Indoor navigation unavailable for this floor.')),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading graph: $e');
      if (mounted) {
        setState(() {
          _isLoadingGraph = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load floor data.')),
        );
      }
    }
  }

  void _onShowRoute() {
    if (_selectedBuilding == null ||
        _selectedFloor == null ||
        _selectedStartNode == null ||
        _selectedEndNode == null ||
        _currentGraph == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IndoorRouteViewScreen(
          buildingModel: _selectedBuilding!,
          floorNo: _selectedFloor!,
          graph: _currentGraph!,
          startNode: _selectedStartNode!,
          endNode: _selectedEndNode!,
        ),
      ),
    );
  }

  void _onNavItemTapped(int index) {
    if (index == 2) return;
    if (index == 0) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else if (index == 1) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const DirectoryScreen()));
    } else if (index == 3) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const OfflineMapsScreen()));
    } else if (index == 4) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('IndoorNavigationSetupScreen: build (isLoading: $_isLoadingBuildings, buildings: ${_buildings.length})');
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: _isLoadingBuildings
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 120.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Custom Header matching Offline Maps
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                                  onPressed: () {
                                    if (Navigator.canPop(context)) {
                                      Navigator.pop(context);
                                    } else {
                                      Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => const HomeScreen()));
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 20),
                              const Text(
                                'Navigate Inside Building',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Content Card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 10)
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Select Route',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                ),
                                const SizedBox(height: 24),
                                _buildDropdown<BuildingModel>(
                                  label: '1. Building',
                                  hint: 'Select Building',
                                  value: _selectedBuilding,
                                  items: _buildings.map((b) {
                                    return DropdownMenuItem(
                                      value: b,
                                      child: Text(b.name),
                                    );
                                  }).toList(),
                                  onChanged: _onBuildingChanged,
                                ),
                                const SizedBox(height: 16),
                                _buildDropdown<int>(
                                  label: '2. Floor',
                                  hint: 'Select Floor',
                                  value: _selectedFloor,
                                  items: _availableFloors.map((f) {
                                    return DropdownMenuItem(
                                      value: f,
                                      child: Text(f == 0 ? 'Ground Floor (0)' : 'Floor $f'),
                                    );
                                  }).toList(),
                                  onChanged:
                                      _selectedBuilding == null ? null : _onFloorChanged,
                                ),
                                const SizedBox(height: 16),
                                if (_isLoadingGraph)
                                  const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(child: CircularProgressIndicator()),
                                  ),
                                _buildDropdown<GraphNode>(
                                  label: '3. Start Node',
                                  hint: 'Select Start Node',
                                  value: _selectedStartNode,
                                  items: _startNodes.map((n) {
                                    return DropdownMenuItem(
                                      value: n,
                                      child: Text('${n.label} (${n.type})'),
                                    );
                                  }).toList(),
                                  onChanged: _currentGraph == null
                                      ? null
                                      : (val) => setState(() => _selectedStartNode = val),
                                ),
                                const SizedBox(height: 16),
                                _buildDropdown<GraphNode>(
                                  label: '4. Destination Node',
                                  hint: 'Select Destination Node',
                                  value: _selectedEndNode,
                                  items: _endNodes.map((n) {
                                    return DropdownMenuItem(
                                      value: n,
                                      child: Text('${n.label} (${n.type})'),
                                    );
                                  }).toList(),
                                  onChanged: _currentGraph == null
                                      ? null
                                      : (val) => setState(() => _selectedEndNode = val),
                                ),
                                const SizedBox(height: 32),
                                Semantics(
                                  label: 'Show Route',
                                  button: true,
                                  child: ElevatedButton(
                                    onPressed: (_selectedBuilding == null ||
                                            _selectedFloor == null ||
                                            _selectedStartNode == null ||
                                            _selectedEndNode == null ||
                                            _currentGraph == null)
                                        ? null
                                        : _onShowRoute,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    child: const Text('Show Route',
                                        style: TextStyle(
                                            fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: CustomBottomNavBar(
              currentIndex: 2,
              onTap: _onNavItemTapped,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: hint,
          container: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                isExpanded: true,
                value: value,
                hint: Text(hint),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
