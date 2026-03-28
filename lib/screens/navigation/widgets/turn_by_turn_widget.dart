import 'package:flutter/material.dart';

/// Uber-style light navigation top bar.
class TurnByTurnWidget extends StatelessWidget {
  final String instruction;
  final String distance;
  final int sign; // GraphHopper sign for the current instruction
  final VoidCallback onClose;
  final String? nextInstruction;
  final int? nextSign;
  final bool isSpeaking;

  const TurnByTurnWidget({
    super.key,
    required this.instruction,
    required this.distance,
    required this.sign,
    required this.onClose,
    this.nextInstruction,
    this.nextSign,
    this.isSpeaking = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Main Turn Banner ───────────────────────────────────────────────
        Container(
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Direction Icon (Black Box)
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getDirectionIcon(sign),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Instruction + Distance
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instruction,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        distance,
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.5),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Microphone Icon with Glow
                _MicrophoneButton(isSpeaking: isSpeaking),
              ],
            ),
          ),
        ),

        // ── Next Move Box (Attached to the left) ──────────────────────────
        if (nextInstruction != null)
          Padding(
            padding: const EdgeInsets.only(top: 0, left: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Then $nextInstruction',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _getDirectionIcon(nextSign ?? 0),
                    color: Colors.white,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  IconData _getDirectionIcon(int sign) {
    switch (sign) {
      case -3:
        return Icons.turn_sharp_left;
      case -2:
        return Icons.turn_left;
      case -1:
        return Icons.turn_slight_left;
      case 1:
        return Icons.turn_slight_right;
      case 2:
        return Icons.turn_right;
      case 3:
        return Icons.turn_sharp_right;
      case 4:
        return Icons.flag_rounded;
      case 5:
        return Icons.sync_rounded;
      case 6:
        return Icons.keyboard_double_arrow_right;
      default:
        return Icons.straight_rounded;
    }
  }
}

class _MicrophoneButton extends StatelessWidget {
  final bool isSpeaking;
  const _MicrophoneButton({required this.isSpeaking});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        shape: BoxShape.circle,
        boxShadow: isSpeaking
            ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ]
            : [],
      ),
      child: Icon(
        Icons.mic_rounded,
        color: isSpeaking ? Colors.blue : Colors.black,
        size: 22,
      ),
    );
  }
}
