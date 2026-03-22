import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/location_model.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart' as app_auth;

class SavedLocationsScreen extends StatefulWidget {
  const SavedLocationsScreen({super.key});

  @override
  State<SavedLocationsScreen> createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<LocationModel> _allSavedLocations = [];
  Map<String, String> _buildingNames = {};
  
  String _searchQuery = '';
  // 0: All, 1: Faculty, 2: Labs, 3: Halls
  int _selectedFilter = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedLocations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLocations() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<app_auth.AuthProvider>();
      final currentUser = auth.currentUser;
      if (currentUser != null && currentUser.savedLocations.isNotEmpty) {
        
        // Reverse to show newest first generally
        final ids = currentUser.savedLocations.reversed.toList();
        final locations = await _firestoreService.getLocationsByIds(ids);
        
        final orderedLocs = <LocationModel>[];
        for (final id in ids) {
          final loc = locations.where((l) => l.id == id).firstOrNull;
          if (loc != null) orderedLocs.add(loc);
        }

        final neededBuildingIds = orderedLocs.map((l) => l.buildingId).whereType<String>().toSet();
        final Map<String, String> bNames = {};
        for (final bId in neededBuildingIds) {
          final building = await _firestoreService.getBuilding(bId);
          if (building != null) {
            bNames[bId] = building.name;
          }
        }

        if (mounted) {
          setState(() {
            _allSavedLocations = orderedLocs;
            _buildingNames = bNames;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _allSavedLocations = [
              LocationModel(
                id: 'sample_faculty_1',
                name: 'Dr. John Doe',
                type: LocationType.faculty,
                buildingId: 'b_sample_1',
                floor: 2,
                roomNumber: '204',
                description: 'Professor of Computer Science',
              ),
              LocationModel(
                id: 'sample_faculty_2',
                name: 'Dr. Jane Smith',
                type: LocationType.faculty,
                buildingId: 'b_sample_1',
                floor: 3,
                roomNumber: '301',
                description: 'Associate Professor of IT',
              ),
              LocationModel(
                id: 'sample_faculty_3',
                name: 'Dr. Robert Brown',
                type: LocationType.faculty,
                buildingId: 'b_sample_2',
                floor: 1,
                roomNumber: '105',
                description: 'Assistant Professor of AI',
              ),
            ];
            _buildingNames = {
              'b_sample_1': 'Main IT Block',
              'b_sample_2': 'New Academic Building',
            };
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
         setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeSavedLocation(String locationId) async {
    final auth = context.read<app_auth.AuthProvider>();
    final user = auth.currentUser;
    if (user != null) {
       await _firestoreService.removeSavedLocation(user.uid, locationId);
       setState(() {
         _allSavedLocations.removeWhere((loc) => loc.id == locationId);
         user.savedLocations.remove(locationId); 
       });
    }
  }

  Future<void> _clearAllSavedLocations() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All'),
        content: const Text('Are you sure you want to clear all saved locations?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final auth = context.read<app_auth.AuthProvider>();
    final user = auth.currentUser;
    if (user != null) {
       await _firestoreService.clearAllSavedLocations(user.uid);
       setState(() {
         _allSavedLocations.clear();
         user.savedLocations.clear();
       });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _setFilter(int filterIndex) {
    setState(() {
      // Toggle off if tapping already selected filter
      if (_selectedFilter == filterIndex) {
          _selectedFilter = 0; 
      } else {
          _selectedFilter = filterIndex;
      }
    });
  }

  List<LocationModel> get _filteredLocations {
    var list = _allSavedLocations;
    
    // Apply Category Filter
    if (_selectedFilter == 1) { // Faculty
      list = list.where((loc) => loc.type == LocationType.faculty).toList();
    } else if (_selectedFilter == 2) { // Labs
      list = list.where((loc) => loc.type == LocationType.lab).toList();
    } else if (_selectedFilter == 3) { // Halls
      list = list.where((loc) => loc.type == LocationType.hall).toList();
    }
    
    // Apply Search Query
    if (_searchQuery.isNotEmpty) {
      list = list.where((loc) => 
         loc.name.toLowerCase().contains(_searchQuery)
      ).toList();
    }
    
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // --- Header ---
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Text(
                      'Saved Location',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  if (_allSavedLocations.isNotEmpty)
                    GestureDetector(
                      onTap: _clearAllSavedLocations,
                      child: const Text(
                        'Clear all',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              
              // --- Search Bar ---
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE), // Light grey matching design
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Icon(Icons.search, color: Color(0xFF888888)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: const InputDecoration(
                          hintText: 'Search cabins, halls, labs...',
                          hintStyle: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF888888), size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // --- Filter Chips ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFilterChip(1, 'Faculty'),
                  _buildFilterChip(2, 'Labs'),
                  _buildFilterChip(3, 'Halls'),
                ],
              ),
              const SizedBox(height: 24),
              
              // --- content ---
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.black))
                    : _filteredLocations.isEmpty
                        ? const Center(
                            child: Text(
                              'No saved locations found.',
                              style: TextStyle(color: Color(0xFF888888), fontSize: 16),
                            ),
                          )
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _filteredLocations.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              return _buildSavedCard(_filteredLocations[index]);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final bool isSelected = _selectedFilter == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _setFilter(index),
        child: Container(
          margin: EdgeInsets.only(
             left: index == 1 ? 0 : 4,
             right: index == 3 ? 0 : 4,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedCard(LocationModel location) {
    String buildingName = _buildingNames[location.buildingId] ?? 'IT Complex';
    if (buildingName.isEmpty) buildingName = 'IT Complex';
    
    final String floorText = location.floor != null ? 'Floor ${location.floor}' : '';
    final String subtitleText = floorText.isEmpty ? buildingName : '$buildingName    $floorText';

    IconData iconData = Icons.location_on;
    if (location.type == LocationType.lab) {
      iconData = Icons.science;
    } else if (location.type == LocationType.faculty) iconData = Icons.person;
    else if (location.type == LocationType.hall) iconData = Icons.meeting_room;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Image Section
            Container(
              margin: const EdgeInsets.all(12),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 2),
                color: const Color(0xFF333333),
              ),
              child: Icon(iconData, color: const Color(0xFFCCCCCC), size: 30),
            ),
            
            // Text Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      location.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Right Side Controls (Walk & Close Buttons)
            Container(
              width: 90,
              margin: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              child: Row(
                children: [
                  // Walk Button
                  const Expanded(
                    child: Center(
                       child: Icon(Icons.directions_walk, color: Colors.black, size: 20),
                    ),
                  ),
                  // Divider Line
                  Container(
                    width: 1,
                    height: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 0),
                    color: Colors.black,
                  ),
                  // Close Button
                  Expanded(
                    child: GestureDetector(
                       onTap: () => _removeSavedLocation(location.id),
                       behavior: HitTestBehavior.opaque,
                       child: const Center(
                          child: Icon(Icons.close, color: Colors.black, size: 18),
                       ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
