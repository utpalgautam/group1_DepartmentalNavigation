import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class NavigationControls extends StatelessWidget {
  final bool isNavigating;
  final bool isLoading;
  final String distance;
  final VoidCallback onToggleTurnByTurn;
  final VoidCallback onStartNavigation;
  final VoidCallback onStopNavigation;

  const NavigationControls({
    super.key,
    required this.isNavigating,
    this.isLoading = false,
    required this.distance,
    required this.onToggleTurnByTurn,
    required this.onStartNavigation,
    required this.onStopNavigation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.map,
            label: 'Turn by Turn',
            onTap: onToggleTurnByTurn,
          ),
          Container(
            width: 1,
            height: 30,
            color: AppColors.border,
          ),
          if (isLoading)
             const Center(child: CircularProgressIndicator())
          else if (!isNavigating)
             _buildControlButton(
                icon: Icons.play_arrow,
                label: 'Start',
                onTap: onStartNavigation,
                isPrimary: true,
             )
          else ...[
             Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Text('Remaining', style: TextStyle(fontSize: 10)),
                   Text(distance, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
             ),
             Container(
               width: 1,
               height: 30,
               color: AppColors.border,
             ),
             _buildControlButton(
               icon: Icons.stop,
               label: 'Stop',
               onTap: onStopNavigation,
             ),
          ]
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPrimary ? AppColors.primary : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isPrimary ? Colors.white : AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isPrimary ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}