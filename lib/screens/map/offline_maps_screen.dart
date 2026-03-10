import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/building_model.dart';
import '../../services/firestore_service.dart';
import '../../services/offline_storage_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../directory/directory_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../home/search_screen.dart';
import 'offline_floor_map_screen.dart';

class OfflineMapsScreen extends StatefulWidget {
  const OfflineMapsScreen({super.key});

  @override
  State<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends State<OfflineMapsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final OfflineStorageService _offlineStorageService = OfflineStorageService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _downloadedBuildingIds = {};
  bool _isLoadingIds = true;
  Set<String> _downloadingIds = {};

  @override
  void initState() {
    super.initState();
    _loadDownloadedIds();
  }

  Future<void> _loadDownloadedIds() async {
    final ids = await _offlineStorageService.getDownloadedBuildingIds();
    if (mounted) {
      setState(() {
        _downloadedBuildingIds = ids;
        _isLoadingIds = false;
      });
    }
  }

  Future<void> _downloadMap(String buildingId) async {
    setState(() {
      _downloadingIds.add(buildingId);
    });

    // Simulate map download duration
    await Future.delayed(const Duration(seconds: 2));
    await _offlineStorageService.markAsDownloaded(buildingId);

    if (mounted) {
      setState(() {
        _downloadingIds.remove(buildingId);
        _downloadedBuildingIds.add(buildingId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Map downloaded successfully!')),
      );
    }
  }

  Future<void> _deleteMap(String buildingId) async {
    await _offlineStorageService.removeDownloadedMap(buildingId);

    if (mounted) {
      setState(() {
        _downloadedBuildingIds.remove(buildingId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Map deleted successfully!')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _onNavItemTapped(int index) {
    if (index == 3) return; // already in MAP

    if (index == 0) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else if (index == 1) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const DirectoryScreen()));
    } else if (index == 2) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const SearchScreen()));
    } else if (index == 4) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
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

                  // --- Header (Back btn & Title) ---
                  Row(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
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
                      const SizedBox(width: 24),
                      const Text(
                        'Offline Maps',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Main Map Card ---
                  _buildMainMapCard(),
                  const SizedBox(height: 24),

                  // --- Search Bar ---
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Icon(Icons.search, color: Color(0xFF666666)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: const InputDecoration(
                              hintText: 'Search Faculty cabins...',
                              hintStyle: TextStyle(
                                color: Color(0xFFAAAAAA),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- List Body ---
                  Expanded(
                    child: _buildBuildingsList(),
                  ),
                  const SizedBox(height: 100), // padding for floating navbar
                ],
              ),
            ),
          ),

          // Floating Bottom Nav Bar
          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: CustomBottomNavBar(
              currentIndex: 3, // Offline maps is index 3
              onTap: _onNavItemTapped,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMapCard() {
    return Container(
      width: double.infinity,
      height: 180,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1D21),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        children: [
          // Background circle designs
          Positioned(
            right: -60,
            top: -40,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFF333333).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 40,
            child: Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFF3B3B3B),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.map,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A4A4A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Intractive',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Whole NITC Map',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingsList() {
    return StreamBuilder<List<BuildingModel>>(
      stream: _firestoreService.streamAllBuildings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            _isLoadingIds) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.black));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var buildings = snapshot.data ?? [];
        if (_searchQuery.isNotEmpty) {
          buildings = buildings
              .where((b) => b.name.toLowerCase().contains(_searchQuery))
              .toList();
        }

        if (buildings.isEmpty) {
          return const Center(child: Text('No buildings found.'));
        }

        final downloadedMaps = buildings
            .where((b) => _downloadedBuildingIds.contains(b.id))
            .toList();
        final availableMaps = buildings
            .where((b) => !_downloadedBuildingIds.contains(b.id))
            .toList();

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            if (downloadedMaps.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 12.0),
                child: Text(
                  'Downloaded Maps',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              ...downloadedMaps.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildBuildingCard(b, isDownloaded: true),
                  )),
              if (availableMaps.isNotEmpty) const SizedBox(height: 16),
            ],
            if (availableMaps.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 12.0),
                child: Text(
                  'Available Maps',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              ...availableMaps.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildBuildingCard(b, isDownloaded: false),
                  )),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBuildingCard(BuildingModel building,
      {required bool isDownloaded}) {
    final imageBytes = building.imageBytes;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -80,
            top: -100,
            bottom: -100,
            child: Container(
              width: 280,
              decoration: const BoxDecoration(
                color: Color(0xFF222222),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Building image — base64 from Firestore, falls back to icon
              Container(
                width: 80,
                height: 80,
                margin:
                    const EdgeInsets.only(left: 12.0, top: 12.0, bottom: 12.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          imageBytes,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.business,
                              color: Color(0xFFCCCCCC),
                              size: 36),
                        ),
                      )
                    : const Icon(Icons.business,
                        color: Color(0xFFCCCCCC), size: 36),
              ),

              const SizedBox(width: 16),

              // Building Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        building.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${building.latitude.toStringAsFixed(4)} N, ${building.longitude.toStringAsFixed(4)} E',
                        style: const TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.layers,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${building.totalFloors} Floors',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Elevated Button
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: _downloadingIds.contains(building.id)
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                      )
                    : isDownloaded
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _deleteMap(building.id),
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent, size: 20),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                    minWidth: 32, minHeight: 32),
                              ),
                              const SizedBox(width: 4),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OfflineFloorMapScreen(
                                          building: building),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(
                                      0xFF333333), // grey button fill
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                ),
                                child: const Text(
                                  'View',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          )
                        : ElevatedButton(
                            onPressed: () => _downloadMap(building.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.download,
                                  size: 16,
                                  color: Colors.black,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Download',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.black),
                                ),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
