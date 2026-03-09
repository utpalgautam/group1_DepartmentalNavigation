import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../widgets/bottom_nav_bar.dart';
import '../auth/login_screen.dart';
import '../directory/directory_screen.dart';
import '../home/home_screen.dart';
import '../home/search_screen.dart';
import '../map/offline_maps_screen.dart';
import 'change_password_screen.dart';
import 'recent_searches_screen.dart';
import 'edit_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedSpeed = 'Normal';
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 60,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });

        if (mounted) {
          final auth = context.read<app_auth.AuthProvider>();
          final success = await auth.updateProfileImage(_imageFile!);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success
                    ? 'Profile image updated!'
                    : (auth.errorMessage ?? 'Upload failed')),
                backgroundColor: success ? Colors.green : Colors.redAccent,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  /// Decodes a base64 data URI to an ImageProvider or returns a NetworkImage.
  ImageProvider? _getProfileImageProvider(String? profileImageUrl) {
    if (profileImageUrl == null || profileImageUrl.isEmpty) return null;

    if (profileImageUrl.startsWith('data:image')) {
      try {
        // Extract base64 part after the comma
        final base64Str = profileImageUrl.split(',').last;
        final bytes = base64Decode(base64Str);
        return MemoryImage(bytes);
      } catch (_) {
        return null;
      }
    }

    // Fallback for legacy URLs
    return NetworkImage(profileImageUrl);
  }

  void _onNavItemTapped(int index) {
    if (index == 4) return;

    if (index == 0) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else if (index == 1) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const DirectoryScreen()));
    } else if (index == 2) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const SearchScreen()));
    } else if (index == 3) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const OfflineMapsScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<app_auth.AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(
                  context), // Though usually used in a tab bar, providing a back button
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // --- Header (Avatar & Name) ---
                  _buildProfileHeader(user?.name ?? 'Guest User',
                      user?.userType.name ?? 'User'),
                  const SizedBox(height: 40),

                  // --- Sections ---
                  _buildSectionTitle('Activity'),
                  _buildCardContainer([
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditDetailsScreen(),
                          ),
                        );
                      },
                      child: _buildListTile('Edit Details'),
                    ),
                    const Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Color(0xFFEEEEEE)),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RecentSearchesScreen(),
                          ),
                        );
                      },
                      child: _buildListTile('Recent Searches'),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Security'),
                  _buildCardContainer([
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen(),
                          ),
                        );
                      },
                      child: _buildListTile('Changed Password'),
                    ),
                    const Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Color(0xFFEEEEEE)),
                    _buildListTile('PIN Lock'),
                  ]),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Preferences'),
                  _buildCardContainer([
                    _buildListTile('Distance Metric'),
                    const Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Color(0xFFEEEEEE)),
                    _buildWalkingSpeedRow(),
                  ]),
                  const SizedBox(height: 48),

                  // --- Log Out Button ---
                  GestureDetector(
                    onTap: () async {
                      // Show confirmation dialog first
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text(
                            'Log Out',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          content: const Text(
                            'Are you sure you want to log out?',
                            style: TextStyle(color: Color(0xFF666666)),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                'Log Out',
                                style: TextStyle(
                                  color: Color(0xFFC0392B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true || !mounted) return;

                      // Sign out from both Google and Firebase
                      // AuthService.signOut() already handles both —
                      // Google sign-out is called first so the account picker
                      // shows again on next login instead of silently re-signing.
                      final navigator = Navigator.of(context);
                      await auth.logout();

                      if (!mounted) return;

                      // Clear entire navigation stack and go to LoginScreen.
                      // AuthWrapper will show LoginScreen automatically since
                      // auth.isAuthenticated becomes false, but we push explicitly
                      // to ensure the stack is fully cleared regardless of depth.
                      navigator.pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      'Log Out',
                      style: TextStyle(
                        color: Color(0xFFC0392B), // Dark red for logout
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 120), // Bottom padding for nav bar
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: CustomBottomNavBar(
              currentIndex: 4,
              onTap: _onNavItemTapped,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String name, String subtitle) {
    final profileUrl =
        context.read<app_auth.AuthProvider>().currentUser?.profileImageUrl;
    final ImageProvider? profileImage = _imageFile != null
        ? FileImage(_imageFile!)
        : _getProfileImageProvider(profileUrl);

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.pastelOrange,
                image: profileImage != null
                    ? DecorationImage(
                        image: profileImage,
                        fit: BoxFit.cover,
                      )
                    : null,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF888888),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: const Text(
            'Edit Photo',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF4A6572), // A muted blue/grey from the mockup
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF999999),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildListTile(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalkingSpeedRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Walking Speed',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _buildSpeedSegment('Slow'),
                _buildSpeedSegment('Normal'),
                _buildSpeedSegment('Fast'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedSegment(String speed) {
    final isSelected = _selectedSpeed == speed;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSpeed = speed;
          });
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            speed,
            style: TextStyle(
              fontSize: 14,
              color: isSelected ? Colors.black : const Color(0xFF666666),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
