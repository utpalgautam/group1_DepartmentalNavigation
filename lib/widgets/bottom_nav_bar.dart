import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<app_auth.AuthProvider>();
    final isGuest = auth.isGuest;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black, // true black background for nav bar
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.home_outlined, 'NavHome'), // Home
          _buildNavItem(1, Icons.contacts_outlined, 'NavDirectory'), // Directory
          _buildNavItem(2, Icons.apartment_outlined, 'NavBuilding'), // Navigate
          _buildNavItem(3, Icons.map_outlined, 'NavMap'), // Offline Map
          if (!isGuest)
            _buildNavItem(4, Icons.account_circle_outlined, 'NavProfile'), // Profile
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    return Semantics(
      label: label,
      container: true,
      button: true,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: () => onTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: isSelected ? 80 : 50,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.black : Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
