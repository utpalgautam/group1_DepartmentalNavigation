import 'package:flutter/material.dart';

class StartNavigationHeader extends StatelessWidget {
  final String buildingName;
  final int? floorNumber;
  final String? cabinName;
  final bool isSpeaking;

  const StartNavigationHeader({
    super.key,
    required this.buildingName,
    this.floorNumber,
    this.cabinName,
    this.isSpeaking = false,
  });

  String _getFloorName(int? floor) {
    if (floor == null) return "";
    if (floor == 0) return "Ground Floor";
    if (floor == 1) return "First Floor";
    if (floor == 2) return "Second Floor";
    if (floor == 3) return "Third Floor";
    return "Floor $floor";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Main Banner ──────────────────────────────────────────────────
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
                  child: const Icon(
                    Icons.straight_rounded, // Default icon for start
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Text Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Navigating to',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        buildingName,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

        // ── Flow Box (Black) ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(top: 0, left: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                _FlowText(text: buildingName),
                if (floorNumber != null) ...[
                  _FlowSeparator(),
                  _FlowText(text: _getFloorName(floorNumber)),
                ],
                if (cabinName != null) ...[
                  _FlowSeparator(),
                  _FlowText(text: cabinName!),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FlowText extends StatelessWidget {
  final String text;
  const _FlowText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _FlowSeparator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 10),
    );
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
