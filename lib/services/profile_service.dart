import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class ProfileService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  Future<XFile?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      rethrow;
    }
  }

  /// Upload profile picture to Firebase Storage
  /// Returns the download URL
  Future<String> uploadProfilePicture(String userId, XFile imageFile) async {
    try {
      debugPrint('📤 Uploading profile picture for user: $userId');
      
      // Create reference to storage location
      final ref = _storage.ref().child('profile_pictures/$userId.jpg');
      
      // Upload file
      final uploadTask = await ref.putFile(File(imageFile.path));
      
      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      debugPrint('✅ Upload complete: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading profile picture: $e');
      rethrow;
    }
  }

  /// Save profile picture URL to Firestore
  Future<void> saveProfilePictureUrl(String userId, String photoUrl) async {
    try {
      debugPrint('💾 Saving profile picture URL to Firestore');
      
      await _firestore.collection('users').doc(userId).update({
        'profilePicture': photoUrl,
        // Keep legacy field for backward compatibility if it exists in the DB.
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Profile picture URL saved');
    } catch (e) {
      debugPrint('❌ Error saving profile picture URL: $e');
      rethrow;
    }
  }

  /// Complete flow: pick, upload, and save
  Future<String?> updateProfilePicture(String userId) async {
    try {
      // Step 1: Pick image
      final imageFile = await pickImage();
      if (imageFile == null) {
        debugPrint('⚠️ No image selected');
        return null;
      }

      // Step 2: Upload to Firebase Storage
      final downloadUrl = await uploadProfilePicture(userId, imageFile);

      // Step 3: Save URL to Firestore
      await saveProfilePictureUrl(userId, downloadUrl);

      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error updating profile picture: $e');
      rethrow;
    }
  }
}
