import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../widgets/bottom_nav_bar.dart';
import '../directory/directory_screen.dart';
import '../home/home_screen.dart';
import '../navigation/indoor_navigation_setup_screen.dart';
import '../map/offline_maps_screen.dart';
import 'change_password_screen.dart';
import 'recent_searches_screen.dart';
import 'edit_details_screen.dart';
import '../../main.dart';
import '../../providers/security_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedSpeed = 'Normal';
  String _selectedDistanceMetric = 'Kilometers';
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
          context,
          MaterialPageRoute(
              builder: (_) => const IndoorNavigationSetupScreen()));
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
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Container(
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
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                }
              },
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
              const SizedBox(height: 12),
              // --- Header (Avatar & Name) ---
              _buildProfileHeader(user?.name ?? 'Guest User', user?.userType?.name ?? 'User'),
              const SizedBox(height: 20),
              
              // --- Sections ---
              _buildSectionTitle('Activity'),
              _buildCardContainer([
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RecentSearchesScreen(),
                      ),
                    );
                  },
                  child: _buildListTile(
                    title: 'Recent Searches',
                    icon: Icons.history,
                    iconColor: Colors.orange[600]!,
                    iconBgColor: Colors.orange[50]!,
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              
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
                  child: _buildListTile(
                    title: 'Change Password',
                    icon: Icons.password, // Lock reset or similar
                    iconColor: Colors.blueGrey[600]!,
                    iconBgColor: Colors.blueGrey[50]!,
                  ),
                ),
                const Divider(height: 1, indent: 64, endIndent: 0, color: Color(0xFFF0F0F0)),
                Consumer<SecurityProvider>(
                  builder: (context, security, child) {
                    return _buildListTile(
                      title: 'PIN Lock',
                      icon: Icons.pin_rounded, // or a similar 123 icon
                      iconColor: Colors.blueGrey[600]!,
                      iconBgColor: Colors.blueGrey[50]!,
                      trailing: Switch(
                        value: security.isDeviceLockEnabled,
                        activeColor: Colors.white,
                        activeTrackColor: Colors.blue[600],
                        onChanged: (value) async {
                          if (value) {
                            final success = await security.authenticate();
                            if (success) {
                              security.setDeviceLockEnabled(true);
                            }
                          } else {
                            final success = await security.authenticate();
                            if (success) {
                              security.setDeviceLockEnabled(false);
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
              ]),
              const SizedBox(height: 16),
              
              _buildSectionTitle('Preferences'),
              _buildCardContainer([
                _buildListTile(
                  title: 'Distance Metric',
                  icon: Icons.straighten,
                  iconColor: Colors.green[600]!,
                  iconBgColor: Colors.green[50]!,
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedDistanceMetric,
                      icon: const Icon(Icons.expand_more, color: Colors.grey, size: 20),
                      style: TextStyle(color: Colors.blue[600], fontSize: 13, fontWeight: FontWeight.w500),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedDistanceMetric = newValue;
                          });
                        }
                      },
                      items: <String>['Meters', 'Kilometers', 'Feet']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 64, endIndent: 0, color: Color(0xFFF0F0F0)),
                _buildWalkingSpeedRow(),
              ]),
              const SizedBox(height: 32),
              
              // --- Log Out Button ---
              GestureDetector(
                onTap: () => _showLogoutDialog(context, auth),
                child: const Center(
                  child: Text(
                    'Log Out',
                    style: TextStyle(
                      color: Color(0xFFEF4444), // Refreshing red color
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 140), // Bottom padding for nav bar
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

  void _showLogoutDialog(BuildContext context, app_auth.AuthProvider auth) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Log Out?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to log out of your account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                await auth.logout();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthWrapper()),
                    (route) => false,
                  );
                }
              },
              child: const Text('Log Out', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
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
              width: 100,
              height: 100,
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
                  color: Colors.blue[600],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF888888),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EditDetailsScreen(),
              ),
            );
          },
          child: Text(
            'Edit Details',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          if (trailing != null) trailing else const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 20),
        ],
      ),
    );
  }

  Widget _buildWalkingSpeedRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildListTile(
          title: 'Walking Speed',
          icon: Icons.directions_walk,
          iconColor: Colors.purple[500]!,
          iconBgColor: Colors.purple[50]!,
          trailing: const SizedBox.shrink(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildSpeedSegment('Slow'),
                _buildSpeedSegment('Normal'),
                _buildSpeedSegment('Fast'),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 16.0, top: 4.0),
          child: Center(
            child: Text(
              'ADJUSTS YOUR ESTIMATED TIME OF ARRIVAL',
              style: TextStyle(
                fontSize: 9,
                color: Color(0xFF9CA3AF),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedSegment(String speed) {
    final isSelected = _selectedSpeed.toLowerCase() == speed.toLowerCase();
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
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            speed.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? Colors.blue[600] : const Color(0xFF6B7280),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
