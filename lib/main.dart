import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'providers/navigation_provider.dart';
import 'providers/security_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'core/constants/colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Single source of truth for the onboarding pref key.
// Both main.dart and onboarding_screen.dart import this.
// ─────────────────────────────────────────────────────────────────────────────
const String kHasSeenOnboarding = 'hasSeenOnboarding';

// ─────────────────────────────────────────────────────────────────────────────
// main() — reads prefs BEFORE runApp so there is zero race condition.
// ─────────────────────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Check onboarding flag BEFORE anything else.
  final prefs = await SharedPreferences.getInstance();
  
  // DEV PURPOSES ONLY: Force onboarding seen
  // await prefs.setBool(kHasSeenOnboarding, true);
  
  final hasSeenOnboarding = prefs.getBool(kHasSeenOnboarding) ?? false;

  // 2. Init Firebase (non-blocking for the nav decision).
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  // 3. Run app, passing the flag in.
  runApp(MyApp(hasSeenOnboarding: hasSeenOnboarding));
}

// ─────────────────────────────────────────────────────────────────────────────
// Root app widget
// ─────────────────────────────────────────────────────────────────────────────
class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  const MyApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => SecurityProvider()),
      ],
      child: MaterialApp(
        title: 'NITC Campus Navigator',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Poppins',
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: false,
            backgroundColor: Colors.transparent,
          ),
        ),
        home: AuthWrapper(hasSeenOnboarding: hasSeenOnboarding),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AuthWrapper — routes based on onboarding + auth state.
//
// Flow:
//   hasSeenOnboarding == false  →  OnboardingScreen   (first launch)
//   hasSeenOnboarding == true   →  wait for Firebase auth
//     auth.isAuthenticated       →  HomeScreen  (or lock screen)
//     !auth.isAuthenticated      →  LoginScreen
// ─────────────────────────────────────────────────────────────────────────────
class AuthWrapper extends StatelessWidget {
  final bool hasSeenOnboarding;
  const AuthWrapper({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    debugPrint('AuthWrapper Built: hasSeenOnboarding=$hasSeenOnboarding');
    
    // 1. If user hasn't seen onboarding, show it first.
    if (!hasSeenOnboarding) {
      return const OnboardingScreen();
    }

    // 2. Otherwise, check authentication state via AuthProvider.
    return Consumer<app_auth.AuthProvider>(
      builder: (context, auth, _) {
        // While initializing, show a splash screen.
        if (!auth.isInitialized) {
          return const _SplashScreen();
        }

        // If authenticated, check for screen lock or go home.
        if (auth.isAuthenticated) {
          return Consumer<SecurityProvider>(
            builder: (context, security, _) {
              if (security.isDeviceLockEnabled && !security.isUnlocked) {
                return _DeviceLockScreen(security: security);
              }
              return const HomeScreen();
            },
          );
        }

        // Not authenticated? Shove 'em to Login.
        return const LoginScreen();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Device-lock screen (extracted for clarity)
// ─────────────────────────────────────────────────────────────────────────────
class _DeviceLockScreen extends StatelessWidget {
  final SecurityProvider security;
  const _DeviceLockScreen({required this.security});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: AppColors.primary),
            const SizedBox(height: 24),
            const Text(
              'App Locked',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => security.authenticate(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Unlock with Device Lock',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Branded splash — shown only while Firebase auth stream is initialising.
// ─────────────────────────────────────────────────────────────────────────────
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_walk_rounded,
                color: Colors.black,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i / 3.0;
                    final phase = (_controller.value - delay).clamp(0.0, 1.0);
                    final opacity = 0.3 + 0.7 * phase;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: opacity),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}