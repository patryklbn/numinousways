import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/user_profile.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Compress image before uploading
  Future<File> compressImage(File file) async {
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return file;

    img.Image resizedImage = img.copyResize(image, width: 150, height: 150);
    final compressedBytes = img.encodeJpg(resizedImage, quality: 80);

    final tempDir = await getTemporaryDirectory();
    final compressedFile = File('${tempDir.path}/compressed_profile_pic.jpg');
    await compressedFile.writeAsBytes(compressedBytes);

    return compressedFile;
  }

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


// Upload profile image and return download URL (always override existing)
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      // Compress the image first
      File compressedImage = await compressImage(imageFile);

      // Use a consistent filename for overriding - 'profile.jpg'
      final fileName = 'profile.jpg';

      // Reference to the storage path with userId and fixed filename
      final storageRef = _storage.ref().child('profile_images/$userId/$fileName');

      // This will override any existing file at this path
      await storageRef.putFile(compressedImage);

      // Get the download URL (with cache busting parameter)
      final downloadUrl = await storageRef.getDownloadURL();

      // Return a URL with cache-busting parameter to prevent showing old images
      final cacheBustedUrl = '$downloadUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      return cacheBustedUrl;
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
