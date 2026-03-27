import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Auth state stream ─────────────────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  // ── Password strength validator ───────────────────────────────────────────
  /// Returns null if valid, or a human-readable error string.
  static String? validatePasswordStrength(String password) {
    if (password.length < 8) return 'Password must be at least 8 characters.';
    if (!password.contains(RegExp(r'[A-Z]'))) return 'Add at least one uppercase letter.';
    if (!password.contains(RegExp(r'[a-z]'))) return 'Add at least one lowercase letter.';
    if (!password.contains(RegExp(r'[0-9]'))) return 'Add at least one number.';
    final specials = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\/`~;]');
    final specialCount = password.split('').where((c) => specials.hasMatch(c)).length;
    if (specialCount < 2) return 'Add at least 2 special characters.';
    return null;
  }

  // ── Register ──────────────────────────────────────────────────────────────
  /// Creates a Firebase Auth account then stores the UserModel in Firestore.
  /// Throws a [String] error message on failure.
  Future<UserModel> registerUser({
    required String email,
    required String password,
    required String name,
    required UserType userType,
    String? branch,
    String? year,
  }) async {
    if (userType == UserType.admin) {
      throw 'Admin accounts cannot be self-registered. '
          'Please contact the system administrator.';
    }

    // ── Duplicate email check ─────────────────────────────────────────────
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email.trim());
      if (methods.isNotEmpty) {
        if (methods.contains('google.com')) {
          throw 'This email is linked to a Google account. Please sign in with Google.';
        }
        throw 'An account with this email already exists. Please sign in.';
      }
    } on FirebaseAuthException catch (e) {
      throw _authErrorMessage(e.code);
    }

    // ── Strong password check ─────────────────────────────────────────────
    final pwError = validatePasswordStrength(password);
    if (pwError != null) throw pwError;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      final now = DateTime.now();

      final userModel = UserModel(
        uid: uid,
        email: email.trim(),
        name: name.trim(),
        branch: branch?.trim(),
        year: year?.trim(),
        userType: userType,
        createdAt: now,
        lastLogin: now,
      );

      await _db.collection('users').doc(uid).set(userModel.toFirestore());
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _authErrorMessage(e.code);
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<UserModel> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;

      final model = await getCurrentUserModel();
      if (model == null) {
        throw 'User profile not found. Please contact support or Administrator.';
      }

      // Update lastLogin timestamp
      await _db.collection('users').doc(uid).update({
        'lastLogin': Timestamp.fromDate(DateTime.now()),
      });

      return model;
    } on FirebaseAuthException catch (e) {
      throw _authErrorMessage(e.code);
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
         throw 'User profile not found. Please contact support or Administrator.';
      }
      throw 'Database error: ${e.message}';
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  // ── Fetch current user profile from Firestore ─────────────────────────────
  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists || doc.data() == null) return null;

    return UserModel.fromFirestore(doc.data()!, user.uid);
  }

  // ── Google Sign In ────────────────────────────────────────────────────────
  Future<UserModel> signInWithGoogle() async {
    try {
      debugPrint('Google Sign-In: Starting...');
      final googleSignIn = GoogleSignIn();

      debugPrint('Google Sign-In: Requesting account prompt...');
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw 'Google Sign-In prompt timed out (15s).',
      );

      if (googleSignInAccount == null) {
        debugPrint('Google Sign-In: User cancelled the flow.');
        throw 'Google Sign-In was cancelled.';
      }

      debugPrint('Google Sign-In: Authenticating account...');
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication.timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw 'Google Authentication timed out (15s).',
      );

      debugPrint('Google Sign-In: Exchanging credentials with Firebase...');
      final AuthCredential googleCredential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      // ── Account linking: if same email exists via email/password, link it ─
      final email = googleSignInAccount.email.trim();
      UserCredential userCredential;

      try {
        final methods = await _auth.fetchSignInMethodsForEmail(email);
        if (methods.contains('password') && _auth.currentUser == null) {
          // Existing email/password account — sign in with Google to link
          debugPrint('Google Sign-In: Linking with existing email/password account...');
          userCredential = await _auth.signInWithCredential(googleCredential)
              .timeout(const Duration(seconds: 15),
                  onTimeout: () => throw 'Firebase credential sign-in timed out (15s).');
          // Try to link Google provider to the account (may already be linked)
          try {
            await userCredential.user!.linkWithCredential(googleCredential);
          } on FirebaseAuthException catch (linkErr) {
            // Ignore if already linked or provider already exists
            debugPrint('Link attempt result: ${linkErr.code}');
          }
        } else {
          userCredential = await _auth.signInWithCredential(googleCredential)
              .timeout(const Duration(seconds: 15),
                  onTimeout: () => throw 'Firebase credential sign-in timed out (15s).');
        }
      } on FirebaseAuthException catch (e) {
        throw _authErrorMessage(e.code);
      }

      final User user = userCredential.user!;

      debugPrint('Google Sign-In: Updating Firestore...');
      // Also check by email in case UID differs (old email/password doc)
      final doc = await _db.collection('users').doc(user.uid).get();
      UserModel userModel;

      if (doc.exists && doc.data() != null) {
        userModel = UserModel.fromFirestore(doc.data()!, user.uid);
        await _db.collection('users').doc(user.uid).update({
          'lastLogin': Timestamp.fromDate(DateTime.now()),
        });
      } else {
        // Search for existing record by email (in case UID is different)
        final existing = await _db
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        final now = DateTime.now();
        if (existing.docs.isNotEmpty) {
          final oldData = existing.docs.first.data();
          userModel = UserModel.fromFirestore(oldData, user.uid);
          // Migrate the document to the new UID
          await _db.collection('users').doc(user.uid).set({
            ...oldData,
            'uid': user.uid,
            'lastLogin': Timestamp.fromDate(now),
          });
        } else {
          // Explicitly sign out of Firebase and Google so no ghost session remains
          await _auth.signOut();
          await GoogleSignIn().signOut();
          throw 'No account found with this Google account. Please sign up first.';
        }
      }

      debugPrint('Google Sign-In: Success!');
      return userModel;
    } on FirebaseAuthException catch (e) {
      debugPrint('Google Sign-In FirebaseAuthException: ${e.code} - ${e.message}');
      throw _authErrorMessage(e.code);
    } catch (e, stacktrace) {
      debugPrint('Google Sign-In general exception: $e');
      debugPrint('Stacktrace: $stacktrace');
      if (e is String) rethrow;
      throw 'Google Sign-In failed: $e';
    }
  }

  // ── Update Profile Image (Base64) ─────────────────────────────────────────
  Future<String> updateProfileImage(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';

    try {
      // Read file bytes and encode to base64
      final Uint8List bytes = await imageFile.readAsBytes();

      // Limit size: if image > 800KB, throw a helpful error
      if (bytes.lengthInBytes > 800 * 1024) {
        throw 'Image too large. Please choose a smaller image (under 800 KB).';
      }

      final String base64Image = base64Encode(bytes);

      // Store the base64 string prefixed with data URI for easy decoding
      final String dataUri = 'data:image/jpeg;base64,$base64Image';

      // Update Firestore document
      await _db.collection('users').doc(user.uid).update({
        'profileImageUrl': dataUri,
      });

      debugPrint('Profile image uploaded as base64 (${bytes.lengthInBytes} bytes)');
      return dataUri;
    } catch (e) {
      throw 'Failed to upload profile image: $e';
    }
  }

  // ── Update Profile Details ────────────────────────────────────────────────
  Future<void> updateProfileDetails({
    required String name,
    String? branch,
    String? year,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';

    try {
      final Map<String, dynamic> updates = {
        'name': name,
        'branch': branch,
        'year': year,
      };

      await _db.collection('users').doc(user.uid).update(updates);

      // Also update Firebase Auth display name
      await user.updateDisplayName(name);
    } catch (e) {
      throw 'Failed to update profile: $e';
    }
  }

  // ── Password Management ───────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _authErrorMessage(e.code);
    }
  }

  Future<void> updatePassword({required String oldPassword, required String newPassword}) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';
    if (user.email == null) throw 'Unable to verify current password. Email not found.';

    try {
      // 1. Re-authenticate to ensure old password is correct
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // 2. Update to new password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw 'Incorrect current password.';
      }
      if (e.code == 'requires-recent-login') {
        throw 'For security reasons, please log out and log back in to change your password.';
      }
      throw _authErrorMessage(e.code);
    }
  }

  // ── Human-readable Firebase error messages ────────────────────────────────
  String _authErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      case 'credential-already-in-use':
        return 'This Google account is already linked to another user.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
