import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';

/// Uber-style light navigation bottom controls.
class CustomNavigationControls extends StatefulWidget {
  final bool isNavigating;
  final bool isLoading;
  final String distance;
  final String time;
  final String? arrivalTime;
  final String instruction;
  final String? base64Image;
  final VoidCallback onStartNavigation;
  final VoidCallback onStopNavigation;
  final VoidCallback onConfirmArrival;

  const CustomNavigationControls({
    super.key,
    required this.isNavigating,
    this.isLoading = false,
    required this.distance,
    required this.time,
    this.arrivalTime,
    required this.instruction,
    this.base64Image,
    required this.onStartNavigation,
    required this.onStopNavigation,
    required this.onConfirmArrival,
  });

  @override
  State<CustomNavigationControls> createState() =>
      _CustomNavigationControlsState();
}

class _CustomNavigationControlsState extends State<CustomNavigationControls> {
  double _sliderValue = 0.0;
  bool _isSliding = false;
  Uint8List? _decodedBytes;
  String? _lastBase64;

  @override
  void didUpdateWidget(CustomNavigationControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isNavigating && oldWidget.isNavigating != widget.isNavigating) {
      _sliderValue = 0.0;
    }
    if (widget.base64Image != _lastBase64) {
      _lastBase64 = widget.base64Image;
      _decodedBytes = null; // Reset to re-decode if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.isNavigating
        ? _buildTrackingControls()
        : _buildPreviewControls();
  }

  // ── Preview (before navigation starts) ─────────────────────────────────
  Widget _buildPreviewControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Title and Location
          Text(
            widget.instruction,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'NIT Calicut, Kerala',
            style: TextStyle(
              fontSize: 14, 
              color: Colors.black.withOpacity(0.4),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          // Image and Info Boxes
          Row(
            children: [
              // Entry Point Image
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildImage(),
                ),
              ),
              const SizedBox(width: 16),
              // Distance and Time Boxes
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _InfoChipVertical(label: widget.distance, icon: Icons.directions_walk_rounded),
                    const SizedBox(height: 12),
                    _InfoChipVertical(label: widget.time, icon: Icons.access_time_filled_rounded),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          widget.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 3,
                  ),
                )
              : _buildSwipeSlider(),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (widget.base64Image != null && widget.base64Image!.isNotEmpty) {
      if (_decodedBytes != null) {
        return Image.memory(
          _decodedBytes!,
          height: 100,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
        );
      }
      try {
        final raw = widget.base64Image!.contains(',') 
            ? widget.base64Image!.split(',').last 
            : widget.base64Image!;
        _decodedBytes = base64Decode(raw);
        _lastBase64 = widget.base64Image;
        return Image.memory(
          _decodedBytes!,
          height: 100,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
        );
      } catch (e) {
        return _buildPlaceholderImage();
      }
    }
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Image.asset(
      'assets/images/entry_point_blue_door.png',
      height: 100,
      fit: BoxFit.cover,
    );
  }

  Widget _buildSwipeSlider() {
    double sliderWidth = 340.0; // Approximate width
    return GestureDetector(
      onHorizontalDragStart: (_) => setState(() => _isSliding = true),
      onHorizontalDragUpdate: (d) {
        if (!_isSliding) return;
        setState(() {
          _sliderValue = (_sliderValue + d.primaryDelta! / (sliderWidth - 64)).clamp(0.0, 1.0);
        });
      },
      onHorizontalDragEnd: (_) {
        if (_sliderValue > 0.8) {
          setState(() {
            _sliderValue = 1.0;
            _isSliding = false;
          });
          widget.onStartNavigation();
        } else {
          setState(() {
            _sliderValue = 0.0;
            _isSliding = false;
          });
        }
      },
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Center Text
            const Center(
              child: Text(
                'Start Navigation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // Right Arrow
            const Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: 20),
                child: Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
              ),
            ),
            // Sliding Button
            Positioned(
              left: _sliderValue * (sliderWidth - 100), // Adjusted for padding and width
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.navigation_rounded,
                  color: Colors.black,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Active Navigation (Uber-style Redesign) ──────────────────────────
  Widget _buildTrackingControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Exit Button (X)
              _CircularIconButton(
                icon: Icons.close_rounded,
                onTap: widget.onStopNavigation,
              ),

              // 2. Center Info
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.time,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.directions_walk_rounded, 
                          color: Colors.black87, size: 24),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.distance} • ${widget.arrivalTime ?? "..."}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.5),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Switch to Indoor (Checkmark)
              _CircularIconButton(
                icon: Icons.check_rounded,
                onTap: widget.onConfirmArrival,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircularIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}

class _InfoChipVertical extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChipVertical({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: Colors.black),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
