import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user_profile.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Fetch user profile data
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        print("No profile found for userId: $userId");
        return UserProfile(id: userId);
      }
    } on FirebaseException catch (e) {
      print("FirebaseException in getUserProfile: $e");
      return null;
    } catch (e) {
      print("Error in getUserProfile: $e");
      return null;
    }
  }

  // Upload profile image and return download URL
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      final storageRef = _storage.ref().child('profile_images/$userId');
      await storageRef.putFile(imageFile);
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      print("FirebaseException in uploadProfileImage: $e");
      return null;
    } catch (e) {
      print("Error in uploadProfileImage: $e");
      return null;
    }
  }

  // Update user profile in Firestore
  Future<void> updateUserProfile(UserProfile userProfile) async {
    try {
      await _firestore.collection('users').doc(userProfile.id).set(userProfile.toMap());
    } on FirebaseException catch (e) {
      print("FirebaseException in updateUserProfile: $e");
    } catch (e) {
      print("Error in updateUserProfile: $e");
    }
  }
}
