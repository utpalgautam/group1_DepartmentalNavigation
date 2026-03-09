import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';

/// Data model for each onboarding page.
class _OnboardingPage {
  final String imagePath;
  final String titleLine1;
  final String boldWord1;
  final String titleLine2;
  final String boldWord2;

  const _OnboardingPage({
    required this.imagePath,
    required this.titleLine1,
    required this.boldWord1,
    required this.titleLine2,
    required this.boldWord2,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      imagePath: 'assets/images/onboarding/onboarding_1.png',
      titleLine1: 'Move ',
      boldWord1: 'smarter,',
      titleLine2: 'Move ',
      boldWord2: 'faster',
    ),
    _OnboardingPage(
      imagePath: 'assets/images/onboarding/onboarding_2.png',
      titleLine1: 'Find your ',
      boldWord1: 'way,',
      titleLine2: 'every ',
      boldWord2: 'day',
    ),
    _OnboardingPage(
      imagePath: 'assets/images/onboarding/onboarding_3.png',
      titleLine1: 'Explore ',
      boldWord1: 'places,',
      titleLine2: 'find ',
      boldWord2: 'spaces',
    ),
    _OnboardingPage(
      imagePath: 'assets/images/onboarding/onboarding_4.png',
      titleLine1: 'Stay ',
      boldWord1: 'connected,',
      titleLine2: 'Stay ',
      boldWord2: 'informed',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: Stack(
        children: [
          // ── PageView fills the screen ──
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) => _buildPage(_pages[index]),
          ),

          // ── Bottom navigation bar ──
          Positioned(
            bottom: 36,
            left: 24,
            right: 24,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  /// Builds a single onboarding page with full-screen illustration + text overlay.
  Widget _buildPage(_OnboardingPage page) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Full-screen illustration ──
        Image.asset(
          page.imagePath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
        ),

        // ── Light gradient at top for text readability ──
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.38,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xDDF2F2F2),
                  Color(0x00F2F2F2),
                ],
              ),
            ),
          ),
        ),

        // ── Title text overlaid on image ──
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line 1
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.black,
                        fontFamily: 'Poppins',
                        height: 1.2,
                      ),
                      children: [
                        TextSpan(text: page.titleLine1),
                        TextSpan(
                          text: page.boldWord1,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Line 2
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.black,
                        fontFamily: 'Poppins',
                        height: 1.2,
                      ),
                      children: [
                        TextSpan(text: page.titleLine2),
                        TextSpan(
                          text: page.boldWord2,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Dark rounded bottom bar with walking icon, dots, and next arrow.
  Widget _buildBottomBar() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),

          // ── Walking person icon (white circle) ──
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_walk,
              color: Colors.black,
              size: 26,
            ),
          ),

          // ── Dot indicators (centered) ──
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 10 : 8,
                  height: isActive ? 10 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.35),
                  ),
                );
              }),
            ),
          ),

          // ── Next / Get Started arrow button ──
          GestureDetector(
            onTap: _nextPage,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 6),
        ],
      ),
    );
  }
}
