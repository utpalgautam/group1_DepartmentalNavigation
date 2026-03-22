import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────
class _OnboardingPage {
  final String imagePath;
  final String titleLine1;
  final String boldWord1;
  final String titleLine2;
  final String boldWord2;
  final String subtitle;

  const _OnboardingPage({
    required this.imagePath,
    required this.titleLine1,
    required this.boldWord1,
    required this.titleLine2,
    required this.boldWord2,
    required this.subtitle,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Main widget
// ─────────────────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // ── Page state ─────────────────────────────────────────────────────────────
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      imagePath: 'assets/images/onboarding/onboarding_1.png',
      titleLine1: 'Move ',
      boldWord1: 'smarter,',
      titleLine2: 'Move ',
      boldWord2: 'faster',
      subtitle: 'Navigate your campus with ease and confidence, every step of the way.',
    ),
    _OnboardingPage(
      imagePath: 'assets/images/onboarding/onboarding_2.png',
      titleLine1: 'Find your ',
      boldWord1: 'way,',
      titleLine2: 'every ',
      boldWord2: 'day',
      subtitle: 'Real-time directions to every block, department, and facility on campus.',
    ),
    _OnboardingPage(
      imagePath: 'assets/images/onboarding/onboarding_3.png',
      titleLine1: 'Explore ',
      boldWord1: 'places,',
      titleLine2: 'find ',
      boldWord2: 'spaces',
      subtitle: 'Discover hidden spots, study zones, and all amenities around you.',
    ),
    _OnboardingPage(
      imagePath: 'assets/images/onboarding/onboarding_4.png',
      titleLine1: 'Stay ',
      boldWord1: 'connected,',
      titleLine2: 'Stay ',
      boldWord2: 'informed',
      subtitle: 'Get updates, announcements, and directions — all in one place.',
    ),
  ];

  // ── Entrance animation controllers ─────────────────────────────────────────
  late AnimationController _entranceController;
  late Animation<double> _imageFadeIn;
  late Animation<double> _imageScale;
  late Animation<double> _textSlideUp;
  late Animation<double> _textFade;
  late Animation<double> _subtitleFade;
  late Animation<double> _bottomBarSlide; // slide up from bottom

  // ── Continuous ambient animation controllers ────────────────────────────────
  late AnimationController _cloudController;    // clouds drift right→left
  late AnimationController _swayController;     // tree sway
  late AnimationController _fountainController; // fountain bounce

  // ── Next button press animation ─────────────────────────────────────────────
  late AnimationController _buttonController;
  late Animation<double> _buttonScale;

  // ── Per-page text transition (fade out / slide up + fade in) ───────────────
  late AnimationController _pageTextController;
  late Animation<double> _pageTextFade;
  late Animation<Offset> _pageTextSlide;

  @override
  void initState() {
    super.initState();
    _initEntranceAnimations();
    _initContinuousAnimations();
    _initButtonAnimation();
    _initPageTextAnimation();

    // Start entrance
    _entranceController.forward();
    // Start continuous ambient loops
    _cloudController.repeat();
    _swayController.repeat(reverse: true);
    _fountainController.repeat(reverse: true);
  }

  void _initEntranceAnimations() {
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _imageFadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _imageScale = Tween<double>(begin: 1.06, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _textSlideUp = Tween<double>(begin: 28, end: 0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.25, 0.7, curve: Curves.easeOut),
      ),
    );
    _textFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
    );
    _subtitleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
    );
    _bottomBarSlide = Tween<double>(begin: 80, end: 0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOutBack),
      ),
    );
  }

  void _initContinuousAnimations() {
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    _swayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _fountainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  void _initButtonAnimation() {
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
  }

  void _initPageTextAnimation() {
    _pageTextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pageTextFade = CurvedAnimation(
      parent: _pageTextController,
      curve: Curves.easeOut,
    );
    _pageTextSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _pageTextController,
      curve: Curves.easeOut,
    ));
    _pageTextController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceController.dispose();
    _cloudController.dispose();
    _swayController.dispose();
    _fountainController.dispose();
    _buttonController.dispose();
    _pageTextController.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _nextPage() async {
    HapticFeedback.lightImpact();
    // Scale down then up the button
    await _buttonController.forward();
    await _buttonController.reverse();

    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    // Animate text in for new page
    _pageTextController.reset();
    _pageTextController.forward();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: Stack(
        children: [
          // ── Full-screen PageView ──────────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) => _buildPage(_pages[index]),
          ),

          // ── Floating bottom nav bar ───────────────────────────────────────
          AnimatedBuilder(
            animation: _bottomBarSlide,
            builder: (context, child) {
              return Positioned(
                bottom: 36 - _bottomBarSlide.value.clamp(0, 80),
                left: 24,
                right: 24,
                child: Opacity(
                  opacity: (1 - _bottomBarSlide.value / 80).clamp(0.0, 1.0),
                  child: child!,
                ),
              );
            },
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Page builder
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPage(_OnboardingPage page) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Illustration with entrance scale ─────────────────────────────
        AnimatedBuilder(
          animation: _entranceController,
          builder: (_, child) => Opacity(
            opacity: _imageFadeIn.value,
            child: Transform.scale(
              scale: _imageScale.value,
              child: child,
            ),
          ),
          child: Image.asset(
            page.imagePath,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
          ),
        ),

        // ── Ambient overlays (clouds, sway, fountain) ─────────────────
        ..._buildAmbientOverlays(),

        // ── Top gradient for text readability ────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.45,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xEEF2F2F2),
                  Color(0x00F2F2F2),
                ],
                stops: [0.0, 1.0],
              ),
            ),
          ),
        ),

        // ── Text content (entrance + per-page transition) ────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: _buildTextContent(page),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Ambient overlay effects (subtle, lightweight, no heavy libs)
  // ─────────────────────────────────────────────────────────────────────────
  List<Widget> _buildAmbientOverlays() {
    return [
      // Floating cloud-like shapes drifting horizontally
      _FloatingCloud(controller: _cloudController, top: 60, initialOffset: 0.0, size: 80, opacity: 0.06),
      _FloatingCloud(controller: _cloudController, top: 90, initialOffset: 0.4, size: 55, opacity: 0.04),

      // Subtle sway overlay to simulate tree/grass movement
      AnimatedBuilder(
        animation: _swayController,
        builder: (_, __) {
          final sway = math.sin(_swayController.value * math.pi) * 3.0;
          return Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Transform.translate(
              offset: Offset(sway, 0),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0x08000000),
                      Color(0x00000000),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),

      // Fountain "pulse" — a subtle radial glow at center-bottom
      AnimatedBuilder(
        animation: _fountainController,
        builder: (_, __) {
          final pulse = 0.5 + _fountainController.value * 0.5;
          return Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Opacity(
                opacity: 0.05 * pulse,
                child: Container(
                  width: 120 * pulse,
                  height: 120 * pulse,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Text content with combined entrance + page-change animations
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTextContent(_OnboardingPage page) {
    return AnimatedBuilder(
      animation: Listenable.merge([_entranceController, _pageTextController]),
      builder: (_, __) {
        // Combine entrance offset and page-change slide
        final entranceOffset = _textSlideUp.value;
        // Only apply entrance opacity on entrance, then full opacity
        final entranceOpacity = _textFade.value;

        return SlideTransition(
          position: _pageTextSlide,
          child: Opacity(
            opacity: (entranceOpacity * _pageTextFade.value).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, entranceOffset),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 48, 32, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Line 1
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 34,
                          color: Colors.black,
                          fontFamily: 'Poppins',
                          height: 1.18,
                          letterSpacing: -0.5,
                        ),
                        children: [
                          TextSpan(text: page.titleLine1),
                          TextSpan(
                            text: page.boldWord1,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    // Line 2
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 34,
                          color: Colors.black,
                          fontFamily: 'Poppins',
                          height: 1.18,
                          letterSpacing: -0.5,
                        ),
                        children: [
                          TextSpan(text: page.titleLine2),
                          TextSpan(
                            text: page.boldWord2,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Subtitle — delayed entrance
                    Opacity(
                      opacity: _subtitleFade.value * _pageTextFade.value,
                      child: Text(
                        page.subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withValues(alpha: 0.50),
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                          height: 1.55,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bottom navigation bar — pill shape with glassmorphism-lite style
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final isLast = _currentPage == _pages.length - 1;

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),

          // ── Walking person icon ─────────────────────────────────────────
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_walk_rounded,
              color: Colors.black,
              size: 26,
            ),
          ),

          // ── Expanded dot indicators ─────────────────────────────────────
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 24 : 8,    // pill expands for active
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.28),
                  ),
                );
              }),
            ),
          ),

          // ── Next / Get Started button ───────────────────────────────────
          GestureDetector(
            onTap: _nextPage,
            child: ScaleTransition(
              scale: _buttonScale,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isLast ? Colors.white : const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    isLast
                        ? Icons.check_rounded
                        : Icons.arrow_forward_ios_rounded,
                    key: ValueKey<bool>(isLast),
                    color: isLast ? Colors.black : Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating cloud overlay widget
// ─────────────────────────────────────────────────────────────────────────────
class _FloatingCloud extends StatelessWidget {
  final AnimationController controller;
  final double top;
  final double initialOffset; // 0.0 – 1.0, phase offset
  final double size;
  final double opacity;

  const _FloatingCloud({
    required this.controller,
    required this.top,
    required this.initialOffset,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        // Move phase by initialOffset so clouds are staggered
        final phase = (controller.value + initialOffset) % 1.0;
        // Drift from right to left across the full screen width + cloud size
        final x = screenWidth - phase * (screenWidth + size + 40);

        return Positioned(
          top: top,
          left: x,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: size,
              height: size * 0.5,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(size * 0.5),
              ),
            ),
          ),
        );
      },
    );
  }
}
