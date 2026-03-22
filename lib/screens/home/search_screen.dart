import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import '../../core/constants/colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/firestore_service.dart';
import '../../models/location_model.dart';
import '../../models/building_model.dart';
import '../../models/search_log_model.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../home/home_screen.dart';
import '../navigation/outdoor_navigation_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  
  List<LocationModel> _suggestedPlaces = [];
  List<LocationModel> _recentSearches = [];
  List<LocationModel> _searchResults = [];
  
  bool _isSearching = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load popular locations
      final popular = await _firestoreService.getPopularLocations(limit: 5);
      
      // Load user's recent searches
      final auth = context.read<app_auth.AuthProvider>();
      final recentIds = auth.currentUser?.recentSearches ?? [];
      
      final recent = await _firestoreService.getLocationsByIds(recentIds.reversed.toList());

      if (mounted) {
        setState(() {
          _suggestedPlaces = popular;
          _recentSearches = recent;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading search data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);
    
    try {
      final results = await _firestoreService.searchLocations(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      debugPrint('Error searching locations: $e');
    }
  }

  void _onLocationSelected(LocationModel location) async {
    // Navigate or pass data back
    final auth = context.read<app_auth.AuthProvider>();
    if (auth.currentUser != null) {
        await _firestoreService.addRecentSearch(auth.currentUser!.uid, location.id);
        await _firestoreService.incrementSearchCount(location.id);
    }
    
    if (!mounted) return;
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
       if (location.buildingId != null) {
          final building = await _firestoreService.getBuilding(location.buildingId!);
          
          // Log search for analytics
          if (building != null) {
            final String platform = kIsWeb ? 'web' : (Platform.isAndroid ? 'android' : 'ios');
            final String searchQuery = _searchController.text.isNotEmpty 
                ? _searchController.text 
                : location.name;

            await _firestoreService.logSearch(SearchLogModel(
              buildingId: building.id,
              buildingName: building.name,
              platform: platform,
              query: searchQuery,
              timestamp: DateTime.now(),
            ));
          }
          
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            if (building != null && building.entryPoints.isNotEmpty) {
               final entryPoint = building.entryPoints.first; // Default to first entry point
               Navigator.push(
                  context,
                  MaterialPageRoute(
                     builder: (_) => OutdoorNavigationScreen(
                        targetBuilding: building,
                        targetEntryPoint: entryPoint,
                        destinationId: location.id,
                        destinationName: location.name,
                        destLat: entryPoint.latitude,
                        destLng: entryPoint.longitude,
                     ),
                  ),
               );
            } else {
               ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Building or entry point data not found.')),
               );
            }
          }
       } else {
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Location data not found.')),
            );
          }
       }
    } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error: $e')),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // --- Header (Back + Search) ---
              Row(
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
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                         }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 16.0, right: 8.0),
                            child: Icon(Icons.search, color: Color(0xFF666666)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              decoration: const InputDecoration(
                                hintText: 'Search cabins, halls, labs...',
                                hintStyle: TextStyle(
                                  color: Color(0xFFAAAAAA),
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                             IconButton(
                               icon: const Icon(Icons.close, color: Color(0xFF666666), size: 20),
                               onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                               },
                             ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // --- Body ---
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.black))
                    : _isSearching
                        ? _buildSearchResults()
                        : _buildDefaultView(),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
);
  }

  Widget _buildDefaultView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_suggestedPlaces.isNotEmpty) ...[
            const Text(
              'Suggested Places',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (int i = 0; i < (_suggestedPlaces.length > 2 ? 2 : _suggestedPlaces.length); i++) ...[
                  if (i > 0) const SizedBox(width: 16),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1.3, // Wider than it is tall, reducing height
                      child: _buildSuggestedCard(_suggestedPlaces[i], i),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),
          ],
          
          if (_recentSearches.isNotEmpty) ...[
            const Text(
              'Recent Searches',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentSearches.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _buildRecentCard(_recentSearches[index]);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text(
          'No specific locations found.\nTry a different search.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF888888),
            fontSize: 16,
          ),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final loc = _searchResults[index];
        return ListTile(
          onTap: () => _onLocationSelected(loc),
          leading: Container(
             padding: const EdgeInsets.all(8),
             decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle
             ),
             child: const Icon(Icons.location_on_outlined, color: Colors.black),
          ),
          title: Text(
            loc.name,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
          ),
          subtitle: Text(
            loc.typeString,
            style: const TextStyle(color: Color(0xFF888888)),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFCCCCCC)),
        );
      },
    );
  }

  Widget _buildSuggestedCard(LocationModel location, int index) {
    // As per user request, use the dark card design for the first, light for the second
    final bool isDark = index == 0;
    
    final Color bgColor = isDark ? const Color(0xFF1B1B1C) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subtitleColor = isDark ? const Color(0xFFAAAAAA) : const Color(0xFF888888);
    final Color faintCircleColor = isDark ? const Color(0xFF242425) : const Color(0xFFE5E5E5);
    final Color iconBoxColor = isDark ? const Color(0xFF333333) : const Color(0xFFCDCDCD);
    
    // Choose an icon based on location type
    IconData iconData = Icons.domain;
    if (location.type == LocationType.lab) iconData = Icons.science;
    else if (location.type == LocationType.faculty) iconData = Icons.person;

    return GestureDetector(
      onTap: () => _onLocationSelected(location),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
             if (!isDark)
               BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4)
               ),
          ]
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: faintCircleColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBoxColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: textColor, size: 24),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Nearby',
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
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

  Widget _buildRecentCard(LocationModel location) {
    return GestureDetector(
      onTap: () => _onLocationSelected(location),
      child: Container(
        color: Colors.transparent, // for tap area
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history, color: Color(0xFF888888), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location.buildingId != null ? 'In Building' : 'Nearby',
                    style: const TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.north_east, color: Color(0xFFAAAAAA), size: 20),
          ],
        ),
      ),
    );
  }
}
