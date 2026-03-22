import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/faculty_model.dart';
import '../../models/hall_model.dart';
import '../../models/lab_model.dart';
import '../../models/location_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../home/home_screen.dart';
import '../navigation/indoor_navigation_setup_screen.dart';
import '../map/offline_maps_screen.dart';
import '../profile/profile_screen.dart';
import '../navigation/outdoor_navigation_screen.dart';

class DirectoryScreen extends StatefulWidget {
  final int initialSegment;
  const DirectoryScreen({super.key, this.initialSegment = 0});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  /// Cache location futures so FutureBuilder doesn't recreate them on rebuild.
  final Map<String, Future<LocationModel?>> _locationFutureCache = {};

  Future<LocationModel?> _getLocationFuture(String locationId) {
    if (locationId.isEmpty) return Future.value(null);
    return _locationFutureCache.putIfAbsent(
      locationId,
      () => _firestoreService.getLocation(locationId),
    );
  }

  // 0: Faculty, 1: Halls, 2: Labs
  int _selectedSegment = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedSegment = widget.initialSegment;
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
    if (index == 1) return; // already in Directory

    if (index == 0) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else if (index == 2) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => const IndoorNavigationSetupScreen()));
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
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                // --- Header + Segment Control (scrolls away) ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // --- Header (Back btn + Title) ---
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.arrow_back,
                                    color: Colors.white, size: 20),
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
                              'Directory',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // --- Segmented Control ---
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              _buildSegmentButton(0, 'Faculty'),
                              _buildSegmentButton(1, 'Halls'),
                              _buildSegmentButton(2, 'Labs'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // --- Sticky Search Bar (scrolls up, then pins at top) ---
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _DirectoryStickySearchBarDelegate(
                    child: Container(
                      color: AppColors.backgroundLight,
                      padding: const EdgeInsets.only(bottom: 16.0, left: 24.0, right: 24.0),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.black, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
                                decoration: InputDecoration(
                                  hintText: _getSearchHint(),
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
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
                                icon: const Icon(Icons.close,
                                    color: Color(0xFF666666), size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // --- List Body ---
                SliverFillRemaining(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: _buildListBody(),
                  ),
                ),
              ],
            ),
          ),

          // Floating Bottom Nav Bar
          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: CustomBottomNavBar(
              currentIndex: 1, // Directory is index 1
              onTap: _onNavItemTapped,
            ),
          ),
        ],
      ),
    );
  }

  String _getSearchHint() {
    switch (_selectedSegment) {
      case 0:
        return 'Search Faculty cabins...';
      case 1:
        return 'Search Halls...';
      case 2:
        return 'Search Labs...';
      default:
        return 'Search...';
    }
  }

  Widget _buildSegmentButton(int index, String title) {
    final isSelected = _selectedSegment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSegment = index;
            _searchController.clear();
            _searchQuery = '';
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF666666),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListBody() {
    switch (_selectedSegment) {
      case 0:
        return _buildFacultyList();
      case 1:
        return _buildHallsList();
      case 2:
        return _buildLabsList();
      default:
        return const SizedBox();
    }
  }

  Widget _buildFacultyList() {
    return StreamBuilder<List<FacultyModel>>(
      stream: _firestoreService.streamAllFaculties(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.black));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var items = snapshot.data ?? [];
        if (_searchQuery.isNotEmpty) {
          items = items
              .where((f) =>
                  f.name.toLowerCase().contains(_searchQuery) ||
                  f.department.toLowerCase().contains(_searchQuery))
              .toList();
        }

        if (items.isEmpty) {
          return const Center(child: Text('No faculty found.'));
        }

        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final faculty = items[index];
            return _buildFacultyCard(faculty);
          },
        );
      },
    );
  }

  // ── Dedicated faculty card matching the reference design ───────────────
  Widget _buildFacultyCard(FacultyModel faculty) {
    return FutureBuilder<LocationModel?>(
      future: _getLocationFuture(faculty.locationId),
      builder: (context, snapshot) {
        final location = snapshot.data;
        final roomLabel = location?.roomNumber ?? 'TBA';
        final floorLabel =
            location?.floor != null ? 'Floor ${location!.floor}' : 'TBA';

        // Decode base64 image if available
        final imageBytes = faculty.imageBytes;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1B1C),
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Decorative circle top-right
              Positioned(
                top: -60,
                right: -50,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF222223),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top row: photo + info ─────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Photo (rounded square)
                        // Outer: white border ring
                        Container(
                          width: MediaQuery.of(context).size.width * 0.20,
                          height: MediaQuery.of(context).size.width * 0.20,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white, width: 3),
                            color: const Color(0xFF333333),
                          ),
                          // Inner: ClipRRect clips the image inside the border
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15), // 18 - 3
                            child: imageBytes != null
                                ? Image.memory(
                                    imageBytes,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.person,
                                        color: Color(0xFFCCCCCC),
                                        size: 36),
                                  )
                                : (faculty.photoUrl != null &&
                                        faculty.photoUrl!.isNotEmpty)
                                    ? Image.network(
                                        faculty.photoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.person,
                                                color: Color(0xFFCCCCCC),
                                                size: 36),
                                      )
                                    : const Icon(Icons.person,
                                        color: Color(0xFFCCCCCC), size: 36),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Info column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                faculty.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              // Role (Professor / Assistant Professor etc.)
                              Text(
                                faculty.role.isNotEmpty
                                    ? faculty.role
                                    : faculty.designation,
                                style: const TextStyle(
                                  color: Color(0xFF909090),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Department
                              Text(
                                faculty.department,
                                style: const TextStyle(
                                  color: Color(0xFF909090),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Email
                              Text(
                                'Email : ${faculty.email}',
                                style: const TextStyle(
                                  color: Color(0xFF909090),
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // ── Bottom row: room pill + floor pill + Navigate ─
                    Row(
                      children: [
                        _buildPill(roomLabel),
                        const SizedBox(width: 8),
                        _buildPill(floorLabel),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _buildNavigateButton(
                                faculty.locationId, context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF333436),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildHallsList() {
    return StreamBuilder<List<HallModel>>(
      stream: _firestoreService.streamAllHalls(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.black));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var items = snapshot.data ?? [];
        if (_searchQuery.isNotEmpty) {
          items = items
              .where((h) => h.name.toLowerCase().contains(_searchQuery))
              .toList();
        }

        if (items.isEmpty) {
          return const Center(child: Text('No halls found.'));
        }

        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final hall = items[index];
            return _buildDirectoryCard(
              title: hall.name,
              subtitle: hall.typeString,
              department: 'Capacity: ${hall.capacity}',
              contactLabel: '',
              contactValue: '',
              locationId: hall.locationId,
              fallbackIcon: Icons.meeting_room,
            );
          },
        );
      },
    );
  }

  Widget _buildLabsList() {
    return StreamBuilder<List<LabModel>>(
      stream: _firestoreService.streamAllLabs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.black));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var items = snapshot.data ?? [];
        if (_searchQuery.isNotEmpty) {
          items = items
              .where((l) =>
                  l.name.toLowerCase().contains(_searchQuery) ||
                  l.department.toLowerCase().contains(_searchQuery))
              .toList();
        }

        if (items.isEmpty) {
          return const Center(child: Text('No labs found.'));
        }

        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final lab = items[index];
            return _buildDirectoryCard(
              title: lab.name,
              subtitle: 'Capacity: ${lab.capacity}',
              department: lab.department,
              contactLabel: 'Lab Incharge',
              contactValue: lab.incharge ?? '',
              locationId: lab.locationId,
              fallbackIcon: Icons.science,
            );
          },
        );
      },
    );
  }

  Widget _buildDirectoryCard({
    required String title,
    required String subtitle,
    required String department,
    required String contactLabel,
    required String contactValue,
    required String locationId,
    String? photoUrl,
    IconData fallbackIcon = Icons.person,
  }) {
    // Determine image placeholders if needed, though we rely on photoUrl/fallback
    return FutureBuilder<LocationModel?>(
      future: _getLocationFuture(locationId),
      builder: (context, snapshot) {
        final location = snapshot.data;
        final roomLabel = location?.roomNumber ?? 'TBA';
        final floorLabel =
            location?.floor != null ? 'Floor ${location!.floor}' : 'TBA';

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF1B1B1C), // very dark grey, almost black
            borderRadius: BorderRadius.circular(28),
          ),
          child: Stack(
            children: [
              // Massive subtle dark circle top-right
              Positioned(
                top: -80,
                right: -60,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF222223), // slightly lighter dark grey
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 16.0),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Image (Rounded Square with white border)
                        Container(
                          width: MediaQuery.of(context).size.width * 0.20,
                          height: MediaQuery.of(context).size.width * 0.20,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 2),
                            color: const Color(0xFF333333),
                            image: photoUrl != null && photoUrl.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(photoUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: photoUrl == null || photoUrl.isEmpty
                              ? Icon(fallbackIcon,
                                  color: const Color(0xFFCCCCCC), size: 36)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        // Text info
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  subtitle,
                                  style: const TextStyle(
                                    color: Color(0xFF909090),
                                    fontSize: 14,
                                    height: 1.3,
                                  ),
                                ),
                                if (department.isNotEmpty)
                                  Text(
                                    department,
                                    style: const TextStyle(
                                      color: Color(0xFF909090),
                                      fontSize: 14,
                                      height: 1.3,
                                    ),
                                  ),
                                if (contactValue.isNotEmpty)
                                  Text(
                                    '$contactLabel : $contactValue',
                                    style: const TextStyle(
                                      color: Color(0xFF909090),
                                      fontSize: 14,
                                      height: 1.3,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Footer Pills
                    Row(
                      children: [
                        _buildFooterPill(roomLabel, isDark: true),
                        const SizedBox(width: 10),
                        _buildFooterPill(floorLabel, isDark: true),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _buildNavigateButton(locationId, context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooterPill(String text,
      {required bool isDark, bool hasArrow = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: hasArrow ? 18 : 16, vertical: hasArrow ? 12 : 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF333436)
            : const Color(0xFFDCDCDC), // dark pill vs light pill
        borderRadius: BorderRadius.circular(hasArrow ? 24 : 18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 14,
              fontWeight: isDark ? FontWeight.w500 : FontWeight.w600,
            ),
          ),
          if (hasArrow) ...[
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 18, color: Colors.black),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigateButton(String locationId, BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final navigator = Navigator.of(context, rootNavigator: true);
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        try {
          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const Center(child: CircularProgressIndicator()),
          );

          final location = await _firestoreService.getLocation(locationId);
          if (location != null && location.buildingId != null && mounted) {
            final building =
                await _firestoreService.getBuilding(location.buildingId!);

            if (mounted) {
              Navigator.pop(context); // Close loading dialog
              if (building != null && building.entryPoints.isNotEmpty) {
                final entryPoint =
                    building.entryPoints.first; // Default to first entry point
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
                  const SnackBar(
                      content: Text('Building or entry point data not found.')),
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
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                'Navigate',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 18, color: Colors.black),
          ],
        ),
      ),
    );
  }
}

class _DirectoryStickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _DirectoryStickySearchBarDelegate({required this.child});

  @override
  double get minExtent => 66.0;

  @override
  double get maxExtent => 66.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _DirectoryStickySearchBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
