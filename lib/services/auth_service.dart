import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  // ── Google Sign-In (google_sign_in ^7.1.1 API) ───────────────────────
  Future<UserModel> signInWithGoogle() async {
    try {
      // v7.x uses a singleton; initialize() must have been called in main()
      final googleSignIn = GoogleSignIn.instance;

      // Trigger the interactive sign-in flow — throws GoogleSignInException
      // if the user cancels or if there is a sign-in failure.
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      // v7.x: .authentication is synchronous, remove await
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Firebase credential — idToken is sufficient for Firebase auth
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final User firebaseUser = userCredential.user!;
      final String uid = firebaseUser.uid;
      final now = DateTime.now();

      final docSnap = await _db.collection('users').doc(uid).get();

      if (!docSnap.exists) {
        // ── NEW user — create Firestore profile ─────────────────────────────
        final userModel = UserModel(
          uid: uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? firebaseUser.email ?? 'User',
          profileImageUrl: firebaseUser.photoURL,
          userType: UserType.student,
          createdAt: now,
          lastLogin: now,
        );
        await _db.collection('users').doc(uid).set(userModel.toFirestore());
        return userModel;
      } else {
        // ── EXISTING user — update lastLogin ──────────────────────────────
        await _db.collection('users').doc(uid).update({
          'lastLogin': Timestamp.fromDate(now),
        });
        return UserModel.fromFirestore(docSnap.data()!, uid);
      }
    } on GoogleSignInException catch (e) {
      // User cancelled or platform error
      throw 'Google Sign-In failed: ${e.description ?? e.code.name}';
    } on FirebaseAuthException catch (e) {
      throw _authErrorMessage(e.code);
    }
  }

  // ── Guest / Anonymous Sign-In ─────────────────────────────────────────────
  Future<UserModel> signInAsGuest() async {
    try {
      final UserCredential cred = await _auth.signInAnonymously();
      final User user = cred.user!;
      return UserModel(
        uid: user.uid,
        email: '',
        name: 'Guest',
        userType: UserType.student,
        createdAt: DateTime.now(),
        isGuest: true,
      );
    } on FirebaseAuthException catch (e) {
      throw _authErrorMessage(e.code);
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
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

      debugPrint(
          'Profile image uploaded as base64 (${bytes.lengthInBytes} bytes)');
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

  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';

    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
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
      case 'operation-not-allowed':
        return 'Sign-in method not enabled in Firebase Console.';
      default:
        return 'Authentication failed: $code';
    }
  }
}
