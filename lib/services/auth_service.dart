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
      // 1. Check if a document already exists with this email
      final existingDocs = await _db
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      // 2. We can optionally fetch sign-in methods to see if they're registered
      // final methods = await _auth.fetchSignInMethodsForEmail(email.trim());
      // if (methods.isNotEmpty && !methods.contains('password')) { ... }

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

      if (existingDocs.docs.isNotEmpty) {
        // ── EXISTING DOCUMENT (e.g. from Google Sign-In) ──
        final existingDoc = existingDocs.docs.first;
        final targetDocId = existingDoc.id;

        // Convert the new model to Map, but remove fields we shouldn't overwrite
        Map<String, dynamic> updateData = userModel.toFirestore();
        updateData
            .remove('uid'); // Keep the original document's authoritative UID
        updateData.remove('createdAt'); // Keep original registration date

        // Link the new Email/Password Auth UID to this existing document
        updateData['authUids'] = FieldValue.arrayUnion([targetDocId, uid]);

        await _db
            .collection('users')
            .doc(targetDocId)
            .set(updateData, SetOptions(merge: true));

        // Return the merged document ensuring we use the authoritative targetDocId
        final updatedDoc = await _db.collection('users').doc(targetDocId).get();
        return UserModel.fromFirestore(updatedDoc.data()!, targetDocId);
      } else {
        // ── NO EXISTING DOCUMENT ──
        await _db.collection('users').doc(uid).set(userModel.toFirestore());
        return userModel;
      }
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
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final model = await getCurrentUserModel();
      if (model == null) {
        throw 'User profile not found. Please contact support or Administrator.';
      }

      // Update lastLogin timestamp using the authoritative document ID
      await _db.collection('users').doc(model.uid).update({
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
        // Check if an Email/Password account already created a profile for this email
        final emailQuery = await _db
            .collection('users')
            .where('email', isEqualTo: firebaseUser.email)
            .limit(1)
            .get();

        if (emailQuery.docs.isNotEmpty) {
          // ── EXISTING user from Email/Password — update lastLogin & link ──
          final existingDoc = emailQuery.docs.first;
          final targetUid = existingDoc.id;

          await _db.collection('users').doc(targetUid).set({
            'lastLogin': Timestamp.fromDate(now),
            'authUids': FieldValue.arrayUnion([targetUid, uid]),
            if (firebaseUser.photoURL != null)
              'profileImageUrl': firebaseUser.photoURL,
          }, SetOptions(merge: true));

          final updatedDoc = await _db.collection('users').doc(targetUid).get();
          return UserModel.fromFirestore(updatedDoc.data()!, targetUid);
        }

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
    return UserModel(
      uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      email: '',
      name: 'Guest',
      userType: UserType.student,
      createdAt: DateTime.now(),
      isGuest: true,
    );
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

    var doc = await _db.collection('users').doc(user.uid).get();

    // If exact UID doc doesn't exist, search by email to find original auth doc
    if (!doc.exists && user.email != null && user.email!.isNotEmpty) {
      final querySnapshot = await _db
          .collection('users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        doc = querySnapshot.docs.first;
      }
    }

    if (!doc.exists || doc.data() == null) return null;

    return UserModel.fromFirestore(doc.data()!, doc.id);
  }

  // ── Update Profile Image (Base64) ─────────────────────────────────────────
  Future<String> updateProfileImage(File imageFile) async {
    final model = await getCurrentUserModel();
    if (model == null) throw 'User not authenticated.';

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

      // Update Firestore document using authoritative ID
      await _db.collection('users').doc(model.uid).update({
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
    final model = await getCurrentUserModel();
    final user = _auth.currentUser;
    if (model == null || user == null) throw 'User not authenticated.';

    try {
      final Map<String, dynamic> updates = {
        'name': name,
        'branch': branch,
        'year': year,
      };

      await _db.collection('users').doc(model.uid).update(updates);

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
