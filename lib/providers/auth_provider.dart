import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _initialized = false; // true after first auth state check completes
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _initialized;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    // Listen to Firebase auth state changes
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  bool _firstCheck = true;

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
    } else {
      if (_firstCheck) {
        final prefs = await SharedPreferences.getInstance();
        final rememberMe = prefs.getBool('remember_me') ?? true;

        if (!rememberMe) {
          await _authService.signOut();
          // The logout will trigger another event with null, so we can just return
          return;
        }
      }

      try {
        _currentUser = await _authService.getCurrentUserModel();
      } catch (_) {
        // Firestore read failed (e.g. security rules not set up yet).
        // Fall back to a minimal model from Firebase Auth so the user
        // still reaches the home page.
        _currentUser = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? firebaseUser.email ?? 'User',
          userType: UserType.student,
          createdAt: DateTime.now(),
        );
      }
    }
    
    _firstCheck = false;
    _initialized = true;
    notifyListeners();
  }


  // ── Register ─────────────────────────────────────────────────────────────
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required UserType userType,
    String? branch,
    String? year,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      _currentUser = await _authService.registerUser(
        email: email,
        password: password,
        name: name,
        userType: userType,
        branch: branch,
        year: year,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      _currentUser = await _authService.loginUser(
        email: email,
        password: password,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Google Sign In ────────────────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    try {
      _currentUser = await _authService.signInWithGoogle();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Update Profile Image ──────────────────────────────────────────────────
  Future<bool> updateProfileImage(File imageFile) async {
    _setLoading(true);
    _clearError();
    try {
      final newUrl = await _authService.updateProfileImage(imageFile);
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(profileImageUrl: newUrl);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Update Profile Details ────────────────────────────────────────────────
  Future<bool> updateProfile({
    required String name,
    String? branch,
    String? year,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.updateProfileDetails(
        name: name,
        branch: branch,
        year: year,
      );
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          name: name,
          branch: branch,
          year: year,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Password Management ───────────────────────────────────────────────────
  Future<bool> resetPassword({required String email}) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changePassword({required String oldPassword, required String newPassword}) async {
    if (oldPassword == newPassword) {
      _errorMessage = "New password cannot be the same as your current password.";
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _clearError();
    try {
      await _authService.updatePassword(oldPassword: oldPassword, newPassword: newPassword);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  void clearError() => _clearError();

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
