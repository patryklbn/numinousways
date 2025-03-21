import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/user_profile.dart';
import 'ai_gallery_service.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Compress image before uploading
  Future<File> compressImage(File file) async {
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return file;

    img.Image resizedImage = img.copyResize(image, width: 300, height: 300);
    final compressedBytes = img.encodeJpg(resizedImage, quality: 95);

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

  // Delete user profile image from storage
  Future<void> deleteProfileImage(String userId) async {
    try {
      // Reference to the profile image directory for this user
      final storageRef = _storage.ref().child('profile_images/$userId');

      // List all files in this directory
      final ListResult result = await storageRef.listAll();

      // Delete each file
      for (var item in result.items) {
        await item.delete();
        print('Deleted profile image: ${item.fullPath}');
      }
    } on FirebaseException catch (e) {
      print("FirebaseException in deleteProfileImage: $e");
    } catch (e) {
      print("Error in deleteProfileImage: $e");
    }
  }

  // Delete user profile from Firestore
  Future<void> deleteUserProfile(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      print('Deleted user profile document for $userId');
    } on FirebaseException catch (e) {
      print("FirebaseException in deleteUserProfile: $e");
      rethrow;
    } catch (e) {
      print("Error in deleteUserProfile: $e");
      rethrow;
    }
  }

  // Delete user's generated AI images
  Future<void> deleteUserAIImages(String userId) async {
    try {
      // Reference to AI images storage for this user
      final storageRef = _storage.ref().child('ai_images/$userId');

      try {
        // List all files in this directory
        final ListResult result = await storageRef.listAll();

        // Delete each file
        for (var item in result.items) {
          await item.delete();
          print('Deleted AI image: ${item.fullPath}');
        }
      } catch (e) {
        // The directory might not exist if user hasn't generated any AI images
        print('No AI images found for user: $userId');
      }
    } on FirebaseException catch (e) {
      print("FirebaseException in deleteUserAIImages: $e");
    } catch (e) {
      print("Error in deleteUserAIImages: $e");
    }
  }

  // Anonymize user's social interactions (posts, comments)
  Future<void> anonymizeUserSocialInteractions(String userId) async {
    try {
      const String anonymousId = 'anonymous_user'; // Fixed ID for all anonymous users
      const String anonymousName = 'Deleted User'; // Consistent display name

      // Anonymize user posts
      final postsQuery = _firestore.collection('posts').where('userId', isEqualTo: userId);
      final postsSnapshot = await postsQuery.get();

      for (var doc in postsSnapshot.docs) {
        await doc.reference.update({
          'userId': anonymousId,
          'userName': anonymousName,  // Make sure we use 'Deleted User' not 'No Name'
          'userProfileImageUrl': null,
          'isAnonymized': true  // Add a flag to indicate this was anonymized
        });
        print('Anonymized post: ${doc.id}');
      }

      // Anonymize user comments
      final commentsQuery = _firestore.collection('comments').where('userId', isEqualTo: userId);
      final commentsSnapshot = await commentsQuery.get();

      for (var doc in commentsSnapshot.docs) {
        await doc.reference.update({
          'userId': anonymousId,
          'userName': anonymousName,  // Make sure we use 'Deleted User' not 'No Name'
          'userProfileImageUrl': null,
          'isAnonymized': true
        });
        print('Anonymized comment: ${doc.id}');
      }

      // Check if the app has a timeline or feed collection
      try {
        final timelineQuery = _firestore.collection('timeline').where('userId', isEqualTo: userId);
        final timelineSnapshot = await timelineQuery.get();

        for (var doc in timelineSnapshot.docs) {
          await doc.reference.update({
            'userId': anonymousId,
            'userName': anonymousName,
            'userProfileImageUrl': null,
            'isAnonymized': true
          });
          print('Anonymized timeline item: ${doc.id}');
        }
      } catch (e) {
        // Timeline collection might not exist, that's okay
        print('Note: No timeline collection found or error accessing it: $e');
      }

      // Also check likes, activity, notifications, etc.
      try {
        final likesQuery = _firestore.collection('likes').where('userId', isEqualTo: userId);
        final likesSnapshot = await likesQuery.get();

        for (var doc in likesSnapshot.docs) {
          await doc.reference.update({
            'userId': anonymousId,
            'userName': anonymousName
          });
        }
      } catch (e) {
        print('Note: No likes collection found or error: $e');
      }

      try {
        final notificationsQuery = _firestore.collection('notifications').where('senderId', isEqualTo: userId);
        final notificationsSnapshot = await notificationsQuery.get();

        for (var doc in notificationsSnapshot.docs) {
          await doc.reference.update({
            'senderId': anonymousId,
            'senderName': anonymousName
          });
        }
      } catch (e) {
        print('Note: No notifications collection found or error: $e');
      }

      print('Anonymized all social interactions for user: $userId');
    } catch (e) {
      print("Error in anonymizeUserSocialInteractions: $e");
    }
  }

  // Delete user's account from Firebase Authentication
  Future<void> deleteUserAccount() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.delete();
        print('Deleted user account from Firebase Auth');
      } else {
        throw Exception('No authenticated user found');
      }
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException in deleteUserAccount: $e");

      // Handle specific auth errors
      if (e.code == 'requires-recent-login') {
        throw Exception('This operation is sensitive and requires recent authentication. Please log in again before retrying.');
      }

      rethrow;
    } catch (e) {
      print("Error in deleteUserAccount: $e");
      rethrow;
    }
  }

  // Complete account deletion process
  Future<void> completeAccountDeletion(String userId) async {
    try {
      // 1. Delete profile image
      await deleteProfileImage(userId);

      // 2. Delete AI images
      await deleteUserAIImages(userId);

      // 3. Clean up AI gallery images for deleted users
      await AiGalleryService().cleanupDeletedUserImages();

      // 4. Anonymize social interactions
      await anonymizeUserSocialInteractions(userId);

      // 5. Delete user profile from Firestore
      await deleteUserProfile(userId);

      // 6. Delete Firebase Auth account (must be last)
      await deleteUserAccount();

    } catch (e) {
      print("Error in completeAccountDeletion: $e");
      rethrow;
    }
  }
  }
