import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../profile/profile_screen.dart';
import 'search_screen.dart';
import '../navigation/indoor_navigation_setup_screen.dart';
import '../directory/directory_screen.dart';
import '../map/offline_maps_screen.dart';
import '../map/explore_map_screen.dart';
import '../../widgets/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _onNavItemTapped(int index) {
    if (index == 0) return;
    if (index == 1) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const DirectoryScreen()));
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
    final user = context.watch<app_auth.AuthProvider>().currentUser;
    final String firstName = user?.name.split(' ').first ?? 'User';
    final String? profileImageUrl = user?.profileImageUrl;

    final double screenHeight = MediaQuery.of(context).size.height;
    // Hero fills ~45 % of screen
    final double heroHeight = screenHeight * 0.5;
    // White card overlaps image by this amount
    const double cardOverlap = 48.0;
    // Search bar dimensions
    const double searchH = 54.0;
    // Search bar floats so its centre aligns with the image/card boundary
    final double searchTop = heroHeight - cardOverlap - searchH - 6;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // ── 1. Hero image – behind everything ─────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: _buildHeroImage(firstName, profileImageUrl),
          ),

          // ── 2. White card – overlaps image, rounded top ───────────────
          Positioned(
            top: heroHeight - cardOverlap + 10,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x28000000),
                    blurRadius: 12,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              // Content starts after the search bar (searchH/2 + a gap)
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMapCard(),
                    const SizedBox(height: 22),
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
          ),

          // ── 3. Search bar – floats at the image/card boundary ─────────
          Positioned(
            top: searchTop,
            left: 20,
            right: 20,
            height: searchH,
            child: _buildSearchBar(),
          ),

          // ── 4. Navbar – always fixed at screen bottom ─────────────────
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: CustomBottomNavBar(
              currentIndex: 0,
              onTap: _onNavItemTapped,
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero image with greeting + avatar ────────────────────────────────────
  Widget _buildHeroImage(String firstName, String? profileImageUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'lib/screens/home/image 36.png',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) =>
              Container(color: const Color(0xFFDDDDDD)),
        ),
        // Light gradient at top for readability
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [Color(0x33000000), Colors.transparent],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hello,Utpal!',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen())),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.pastelOrange,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      image: _getAvatarImage(profileImageUrl),
                    ),
                    child: profileImageUrl == null || profileImageUrl.isEmpty
                        ? const Icon(Icons.person,
                            color: Colors.white, size: 28)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Returns a DecorationImage for the avatar, handling base64 data URIs.
  DecorationImage? _getAvatarImage(String? profileImageUrl) {
    if (profileImageUrl == null || profileImageUrl.isEmpty) return null;

    ImageProvider provider;
    if (profileImageUrl.startsWith('data:image')) {
      try {
        final base64Str = profileImageUrl.split(',').last;
        final bytes = base64Decode(base64Str);
        provider = MemoryImage(bytes);
      } catch (_) {
        return null;
      }
    } else {
      provider = NetworkImage(profileImageUrl);
    }

    return DecorationImage(image: provider, fit: BoxFit.cover);
  }

  // ── Search bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const SearchScreen())),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          children: [
            SizedBox(width: 18),
            Icon(Icons.search, color: Color(0xFF888888), size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Search cabins, halls, labs...',
                style: TextStyle(
                  color: Color(0xFFAAAAAA),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            SizedBox(width: 18),
          ],
        ),
      ),
    );
  }

  // ── Explore NITC Map card ─────────────────────────────────────────────────
  Widget _buildMapCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ExploreMapScreen())),
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(36),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -55,
              top: -55,
              child: Container(
                width: 210,
                height: 210,
                decoration: const BoxDecoration(
                  color: AppColors.accentDark,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 24,
              top: -40,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2C2C2C),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.map_outlined,
                      color: Colors.white, size: 30),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Intractive',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ),
                  const Spacer(),
                  const Text('Explore NITC Map',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      )),
                  const SizedBox(height: 6),
                  const Text(
                    'Find your way around campus locations.\ninstantly.',
                    style: TextStyle(
                        color: Color(0xFFAAAAAA), fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick Actions ─────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick action',
            style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 1 – Search
            _buildActionItem(
              icon: Icons.search,
              label: 'Search',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SearchScreen())),
            ),
            // 2 – Labs
            _buildActionItem(
              icon: Icons.science_outlined,
              label: 'Labs',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const DirectoryScreen(initialSegment: 2))),
            ),
            // 3 – Buildings
            _buildActionItem(
              icon: Icons.apartment_outlined,
              label: 'Buildings',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const OfflineMapsScreen())),
            ),
            // 4 – Faculty
            _buildActionItem(
              icon: Icons.person_outline,
              label: 'Faculty',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const DirectoryScreen(initialSegment: 0))),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56, // Smaller as requested
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFB8C8E8),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF3A3A5C), size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
