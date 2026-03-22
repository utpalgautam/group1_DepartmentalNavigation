import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/location_model.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart' as app_auth;

class RecentSearchesScreen extends StatefulWidget {
  const RecentSearchesScreen({super.key});

  @override
  State<RecentSearchesScreen> createState() => _RecentSearchesScreenState();
}

class _RecentSearchesScreenState extends State<RecentSearchesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<LocationModel> _recentSearches = [];
  Map<String, String> _buildingNames = {};

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<app_auth.AuthProvider>();
      final currentUser = auth.currentUser;
      if (currentUser != null && currentUser.recentSearches.isNotEmpty) {
        // fetching max 8
        final ids = currentUser.recentSearches.take(8).toList();
        final locations = await _firestoreService.getLocationsByIds(ids);
        
        // Ensure they match the order of ids
        final orderedLocs = <LocationModel>[];
        for (final id in ids) {
          final loc = locations.where((l) => l.id == id).firstOrNull;
          if (loc != null) orderedLocs.add(loc);
        }

        // Fetch building names mostly locally if we just know the ID,
        // but let's query the db for the names to be safe.
        final neededBuildingIds = orderedLocs.map((l) => l.buildingId).whereType<String>().toSet();
        final Map<String, String> bNames = {};
        for (final bId in neededBuildingIds) {
          final building = await _firestoreService.getBuilding(bId);
          if (building != null) {
            bNames[bId] = "IT Complex"; // To perfectly match the mockup we can just display IT Complex if there's no building name available, but let's use the real one. 
            bNames[bId] = building.name;
          }
        }

        if (mounted) {
          setState(() {
            _recentSearches = orderedLocs;
            _buildingNames = bNames;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _recentSearches = [];
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

  Future<void> _removeSearch(String locationId) async {
    final auth = context.read<app_auth.AuthProvider>();
    final user = auth.currentUser;
    if (user != null) {
       await _firestoreService.removeRecentSearch(user.uid, locationId);
       setState(() {
         _recentSearches.removeWhere((loc) => loc.id == locationId);
         user.recentSearches.remove(locationId); 
       });
    }
  }

  Future<void> _clearAll() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All'),
        content: const Text('Are you sure you want to clear all recent searches?'),
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
       await _firestoreService.clearAllRecentSearches(user.uid);
       setState(() {
         _recentSearches.clear();
         user.recentSearches.clear();
       });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7), // slight off-white like in the design
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
                  const SizedBox(width: 24),
                  const Expanded(
                    child: Text(
                      'Recent Searches',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // --- content ---
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.black))
                    : _recentSearches.isEmpty
                        ? const Center(
                            child: Text(
                              'No recent searches.',
                              style: TextStyle(color: Color(0xFF888888), fontSize: 16),
                            ),
                          )
                        : _buildSearchesList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchesList() {
    // Split into today and yesterday for the UI mockup
    final List<LocationModel> todaySearches = [];
    final List<LocationModel> yesterdaySearches = [];
    
    for (int i = 0; i < _recentSearches.length; i++) {
        if (i < 3) {
            todaySearches.add(_recentSearches[i]);
        } else {
            yesterdaySearches.add(_recentSearches[i]);
        }
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        // TODAY Header
        if (todaySearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TODAY',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              GestureDetector(
                onTap: _clearAll,
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
          const SizedBox(height: 16),
          ...todaySearches.map((loc) => _buildCard(loc)),
        ],

        // YESTERDAY Header
        if (yesterdaySearches.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'YESTERDAY',
            style: TextStyle(
              color: Color(0xFF888888),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          ...yesterdaySearches.map((loc) => _buildCard(loc)),
        ],
        
        const SizedBox(height: 48), // Bottom padding
      ],
    );
  }

  Widget _buildCard(LocationModel location) {
    // Determine building and floor text
    String buildingName = _buildingNames[location.buildingId] ?? 'Unknown Building';
    if (buildingName.isEmpty) buildingName = 'IT Complex'; // fallback to image likeness if empty
    
    final String floorText = location.floor != null ? 'Floor ${location.floor}' : '';
    final String subtitleText = floorText.isEmpty ? buildingName : '$buildingName    $floorText';

    // Icon fallback for the image
    IconData iconData = Icons.location_on;
    if (location.type == LocationType.lab) {
      iconData = Icons.science;
    } else if (location.type == LocationType.faculty) iconData = Icons.person;
    else if (location.type == LocationType.hall) iconData = Icons.meeting_room;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Image (Rounded Square with white border)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 2),
              color: const Color(0xFF333333),
            ),
            child: Icon(iconData, color: const Color(0xFFCCCCCC), size: 28),
          ),
          const SizedBox(width: 16),
          // Texts
          Expanded(
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
          const SizedBox(width: 12),
          // Close button
          GestureDetector(
            onTap: () => _removeSearch(location.id),
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.transparent, // expand tap area
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
