import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Auth methods
  static Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      return null;
    }
  }

  static Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      return null;
    }
  }

  static Future<User?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential result = await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e) {
      return null;
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      // Password reset error
    }
  }

  // Firestore methods
  static CollectionReference get usersCollection => _firestore.collection('users');

  static Future<void> addUser({
    required String uid,
    required String email,
    required String name,
    String? phoneNumber,
    String? bio,
    String? relationshipStatus,
    Map<String, String>? socialMediaLinks,
    Map<String, String>? privacySettings,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'phoneNumber': phoneNumber,
        'bio': bio,
        'relationshipStatus': relationshipStatus ?? 'Single',
        'socialMediaLinks': socialMediaLinks,
        'privacySettings': privacySettings ?? {
          'profileAccess': 'anyone',
          'locationAccess': 'friends_only',
          'photoAccess': 'friends_only',
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Add user error
    }
  }

  static Future<void> updateUserProfile({
    required String uid,
    String? phoneNumber,
    String? bio,
    String? relationshipStatus,
    Map<String, String>? socialMediaLinks,
    Map<String, String>? privacySettings,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (bio != null) 'bio': bio,
        if (relationshipStatus != null) 'relationshipStatus': relationshipStatus,
        if (socialMediaLinks != null) 'socialMediaLinks': socialMediaLinks,
        if (privacySettings != null) 'privacySettings': privacySettings,
      });
    } catch (e) {
      // Update user error
      print('Error updating user profile: $e');
    }
  }
}