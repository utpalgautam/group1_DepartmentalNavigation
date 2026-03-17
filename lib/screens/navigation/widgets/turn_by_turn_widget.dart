import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class TurnByTurnWidget extends StatelessWidget {
  final String instruction;
  final String distance;
  final VoidCallback onClose;

  const TurnByTurnWidget({
    super.key,
    required this.instruction,
    required this.distance,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE), // Google blue light
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.turn_slight_right, // Example dynamic icon could be passed
                  color: Color(0xFF1A73E8), // Google blue
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Turn-by-Turn',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.close, color: Colors.grey[400], size: 22),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            instruction,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.straighten, size: 16, color: Color(0xFF1A73E8)),
                const SizedBox(width: 8),
                Text(
                  distance,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1A73E8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
