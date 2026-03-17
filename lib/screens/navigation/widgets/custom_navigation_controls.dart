import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class CustomNavigationControls extends StatefulWidget {
  final bool isNavigating;
  final bool isLoading;
  final String distance;
  final String time;
  final String instruction;
  final VoidCallback onStartNavigation;
  final VoidCallback onStopNavigation;
  final VoidCallback onConfirmArrival;

  const CustomNavigationControls({
    super.key,
    required this.isNavigating,
    this.isLoading = false,
    required this.distance,
    required this.time,
    required this.instruction,
    required this.onStartNavigation,
    required this.onStopNavigation,
    required this.onConfirmArrival,
  });

  @override
  State<CustomNavigationControls> createState() => _CustomNavigationControlsState();
}

class _CustomNavigationControlsState extends State<CustomNavigationControls> {
  double _sliderValue = 0.0;
  bool _isSliding = false;

  @override
  void didUpdateWidget(CustomNavigationControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isNavigating && oldWidget.isNavigating != widget.isNavigating) {
      _sliderValue = 0.0;
    } else if (!widget.isNavigating && _sliderValue >= 1.0 && !widget.isLoading) {
       _sliderValue = 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isNavigating) {
      return _buildTrackingControls();
    } else {
      return _buildPreviewControls();
    }
  }

  Widget _buildPreviewControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.instruction,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'NIT Calicut, Keralam',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Small mock badges (as seen in the mockup)
          Row(
            children: [
              Container(
                height: 24,
                width: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 24,
                width: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Image placeholder for destination
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 24),
          
          // Custom Slider
          widget.isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _buildSlider(),
        ],
      ),
    );
  }

  Widget _buildSlider() {
    return GestureDetector(
      onHorizontalDragStart: (details) {
        setState(() {
          _isSliding = true;
        });
      },
      onHorizontalDragUpdate: (details) {
        if (!_isSliding) return;
        setState(() {
          // Calculate percentage based on total width (approx 300) minus handle width (56)
          _sliderValue += details.primaryDelta! / 250;
          _sliderValue = _sliderValue.clamp(0.0, 1.0);
        });
      },
      onHorizontalDragEnd: (details) {
        if (_sliderValue > 0.8) {
          // Trigger navigation
          setState(() {
            _sliderValue = 1.0;
            _isSliding = false;
          });
          widget.onStartNavigation();
        } else {
          // Snap back
          setState(() {
            _sliderValue = 0.0;
            _isSliding = false;
          });
        }
      },
      child: Container(
        height: 64,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Stack(
          children: [
            // Text in background
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Text(
                    'Navigate',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${widget.time} walk • ${widget.distance}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Right Arrow
            const Positioned(
              right: 24,
              top: 0,
              bottom: 0,
              child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            ),
            // Sliding Handle
            Align(
              alignment: Alignment.centerLeft,
              child: FractionalTranslation(
                translation: Offset(_sliderValue * 4.5, 0.0), // Multiplier depends on container/handle size ratio
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.navigation, color: Colors.black, size: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.distance,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.time} ahead',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blueGrey[400],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Flow Blue line',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey[300],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'To reach\nDestination.',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: InkWell(
                    onTap: widget.onConfirmArrival,
                    borderRadius: BorderRadius.circular(30),
                    child: const Center(
                      child: Text(
                        'Confirm',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: InkWell(
                    onTap: widget.onStopNavigation,
                    borderRadius: BorderRadius.circular(30),
                    child: const Center(
                      child: Text(
                        'Exit Navigation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
