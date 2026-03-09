import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // On web: use Firebase Auth's signInWithPopup directly
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // On mobile: use google_sign_in package
        final GoogleSignInAccount? googleUser =
            await _googleSignIn.authenticate();
        if (googleUser == null) {
          // User cancelled
          return null;
        }
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      final User? user = userCredential.user;

      if (user != null) {
        // Check if user already exists in Firestore
        final DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();

        if (!doc.exists) {
          // New user — save with default "student" role
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'role': 'student',
            'name': user.displayName ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return userCredential;
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  // Check if user is signed in
  bool isSignedIn() => _auth.currentUser != null;

  // Get user display name
  String? getUserDisplayName() => _auth.currentUser?.displayName;

  // Get user email
  String? getUserEmail() => _auth.currentUser?.email;

  // Get user photo URL
  String? getUserPhotoUrl() => _auth.currentUser?.photoURL;
}
