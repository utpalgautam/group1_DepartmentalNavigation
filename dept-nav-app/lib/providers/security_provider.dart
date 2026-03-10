import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityProvider extends ChangeNotifier {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isDeviceLockEnabled = false;
  bool _isUnlocked = false;

  bool get isDeviceLockEnabled => _isDeviceLockEnabled;
  bool get isUnlocked => _isUnlocked;

  SecurityProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDeviceLockEnabled = prefs.getBool('device_lock_enabled') ?? false;
    notifyListeners();
  }

  Future<void> setDeviceLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('device_lock_enabled', enabled);
    _isDeviceLockEnabled = enabled;
    if (!enabled) {
      _isUnlocked = true; // No lock, so it's "unlocked"
    }
    notifyListeners();
  }

  Future<bool> authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        return false;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      _isUnlocked = didAuthenticate;
      notifyListeners();
      return didAuthenticate;
    } catch (e) {
      debugPrint("Authentication error: $e");
      return false;
    }
  }

  void lock() {
    if (_isDeviceLockEnabled) {
      _isUnlocked = false;
      notifyListeners();
    }
  }
}
