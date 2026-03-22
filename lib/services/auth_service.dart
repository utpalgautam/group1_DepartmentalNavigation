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
      final googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();

      if (googleSignInAccount == null) {
        throw 'Google Sign-In was cancelled.';
      }

      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final User user = userCredential.user!;
      
      final doc = await _db.collection('users').doc(user.uid).get();
      UserModel userModel;
      
      if (doc.exists && doc.data() != null) {
        userModel = UserModel.fromFirestore(doc.data()!, user.uid);
        await _db.collection('users').doc(user.uid).update({
          'lastLogin': Timestamp.fromDate(DateTime.now()),
        });
      } else {
        final now = DateTime.now();
        userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? 'Google User',
          userType: UserType.student, // default
          createdAt: now,
          lastLogin: now,
        );
        await _db.collection('users').doc(user.uid).set(userModel.toFirestore());
      }
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _authErrorMessage(e.code);
    } catch (e) {
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
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
