import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class AiGalleryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // IMPORTANT: Do not commit real keys to source control in production.
  // Store securely or call from your own backend.
  static const String _openAIApiKey =
      "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";

  // Storage optimization constants
  static const int thumbnailMaxSize = 512; // Size for thumbnails (grid view)
  static const int detailMaxSize = 1024;   // Size for detail view
  static const int imageQuality = 85;      // JPEG quality (0-100)
  static const int minLikesToKeep = 3;     // Min likes for an image to be kept indefinitely
  static const int daysToKeepUnlikedImages = 30; // Days to keep images with fewer likes

  /// 1) Generate image from prompt using DALL·E 3
  ///    Returns a URL to the generated image from OpenAI.
  Future<String> generateImageFromPrompt(String prompt) async {
    const String url = "https://api.openai.com/v1/images/generations";
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $_openAIApiKey",
    };
    final body = {
      "prompt": prompt,
      "model": "dall-e-3", // Specify the DALL·E 3 model here
      "n": 1,          // how many images to generate
      "size": "1024x1024"  // possible sizes: 256x256, 512x512, 1024x1024
    };

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to generate image. Status code: ${response.statusCode}, body: ${response.body}",
      );
    }

    final decoded = jsonDecode(response.body);
    // We requested n=1, so there's only one image in "data"
    final String imageUrl = decoded["data"][0]["url"];
    return imageUrl;
  }

  /// 2) Download, compress, and upload the generated image to Firebase Storage
  ///    This is MANDATORY because DALL-E URLs expire after a short period
  Future<Map<String, String>> uploadAiImage(String imagePathOrUrl, String userId) async {
    try {
      // Download the AI image from the OpenAI URL
      final response = await http.get(Uri.parse(imagePathOrUrl));
      if (response.statusCode != 200) {
        throw Exception("Failed to download AI image from OpenAI.");
      }

      final bytes = response.bodyBytes;
      final String fileId = const Uuid().v4();

      // Upload both a thumbnail version and a detail version
      final thumbnailUrl = await _uploadCompressedImage(
          bytes,
          userId,
          fileId,
          thumbnailMaxSize,
          'thumbnail'
      );

      final detailUrl = await _uploadCompressedImage(
          bytes,
          userId,
          fileId,
          detailMaxSize,
          'detail'
      );

      // Calculate and store the size of the image in KB
      final imageSizeKB = bytes.length / 1024;

      return {
        'thumbnailUrl': thumbnailUrl,
        'detailUrl': detailUrl,
        'sizeKB': imageSizeKB.toStringAsFixed(2),
      };
    } catch (e) {
      print("Error uploading image to Firebase Storage: $e");
      rethrow;
    }
  }

  /// Helper method to compress and upload an image
  Future<String> _uploadCompressedImage(
      Uint8List bytes,
      String userId,
      String fileId,
      int maxSize,
      String type,
      ) async {
    try {
      // Compress the image
      final Uint8List compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minHeight: maxSize,
        minWidth: maxSize,
        quality: imageQuality,
        format: CompressFormat.jpeg,
      );

      // Create a reference to the file location
      final ref = _storage.ref().child('ai_images/$userId/${fileId}_${type}.jpg');

      // Upload to Firebase Storage
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'size': '${compressedBytes.length}',
          'type': type,
        },
      );

      await ref.putData(compressedBytes, metadata);

      // Return final download URL
      return await ref.getDownloadURL();
    } catch (e) {
      print("Error compressing and uploading image: $e");
      rethrow;
    }
  }

  /// 3) Save image data to Firestore with additional metadata
  Future<void> addAiImage({
    required String prompt,
    required Map<String, String> imageUrls,
    required String userId,
    required String userName,
  }) async {
    await _firestore.collection('ai_images').add({
      'prompt': prompt,
      'imageUrl': imageUrls['detailUrl'], // For backward compatibility
      'thumbnailUrl': imageUrls['thumbnailUrl'],
      'detailUrl': imageUrls['detailUrl'],
      'userId': userId,
      'userName': userName,
      'createdAt': FieldValue.serverTimestamp(),
      'likes': <String>[],
      'sizeKB': imageUrls['sizeKB'],
      'shouldKeep': false, // Will be updated based on likes
    });

    // Update storage usage statistics
    await _updateStorageStats(double.parse(imageUrls['sizeKB'] ?? '0'));
  }

  /// 4) A Stream to fetch all images (real-time)
  Stream<QuerySnapshot> streamAllImages() {
    return _firestore
        .collection('ai_images')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  ///  Toggle Like
  Future<void> toggleLike({
    required String docId,
    required String userId,
    required bool currentlyLiked,
  }) async {
    final docRef = _firestore.collection('ai_images').doc(docId);

    if (currentlyLiked) {
      await docRef.update({
        'likes': FieldValue.arrayRemove([userId]),
      });

      // Check if we need to update the shouldKeep flag
      final doc = await docRef.get();
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        final likes = List<String>.from(data['likes'] ?? []);
        if (likes.length < minLikesToKeep) {
          await docRef.update({'shouldKeep': false});
        }
      }
    } else {
      await docRef.update({
        'likes': FieldValue.arrayUnion([userId]),
      });

      // Check if we need to update the shouldKeep flag
      final doc = await docRef.get();
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        final likes = List<String>.from(data['likes'] ?? []);
        // +1 because we just added a like but it's not in the data yet
        if (likes.length + 1 >= minLikesToKeep) {
          await docRef.update({'shouldKeep': true});
        }
      }
    }
  }

  /// Delete image from gallery
  Future<void> deleteAiImage(String docId) async {
    try {
      // Get the document to find the image URLs
      final doc = await _firestore.collection('ai_images').doc(docId).get();
      final data = doc.data();
      double sizeKB = 0;

      if (data != null) {
        // Get image size for storage stats update
        if (data['sizeKB'] != null) {
          sizeKB = double.tryParse(data['sizeKB'].toString()) ?? 0;
        }

        // Delete thumbnail image if it exists
        if (data['thumbnailUrl'] != null) {
          final thumbnailUrl = data['thumbnailUrl'] as String;
          if (thumbnailUrl.contains('firebasestorage')) {
            try {
              await _storage.refFromURL(thumbnailUrl).delete();
            } catch (e) {
              print('Error deleting thumbnail file: $e');
            }
          }
        }

        // Delete detail image if it exists
        if (data['detailUrl'] != null) {
          final detailUrl = data['detailUrl'] as String;
          if (detailUrl.contains('firebasestorage')) {
            try {
              await _storage.refFromURL(detailUrl).delete();
            } catch (e) {
              print('Error deleting detail file: $e');
            }
          }
        }

        // Delete for backward compatibility
        if (data['imageUrl'] != null &&
            data['imageUrl'] != data['detailUrl'] &&
            data['imageUrl'] != data['thumbnailUrl']) {
          final imageUrl = data['imageUrl'] as String;
          if (imageUrl.contains('firebasestorage')) {
            try {
              await _storage.refFromURL(imageUrl).delete();
            } catch (e) {
              print('Error deleting legacy image file: $e');
            }
          }
        }
      }

      // Delete the document from Firestore
      await _firestore.collection('ai_images').doc(docId).delete();

      // Update storage stats
      if (sizeKB > 0) {
        await _updateStorageStats(-sizeKB);
      }
    } catch (e) {
      print('Error in deleteAiImage: $e');
      rethrow;
    }
  }

  /// Cleanup old images
  Future<void> cleanupOldImages() async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeepUnlikedImages));

      // Find images older than cutoff date with fewer than minLikesToKeep likes
      // and not marked for keeping
      final snapshot = await _firestore
          .collection('ai_images')
          .where('shouldKeep', isEqualTo: false)
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      print('Found ${snapshot.docs.length} images to clean up');

      // Delete each image
      for (final doc in snapshot.docs) {
        await deleteAiImage(doc.id);
      }

      print('Cleaned up ${snapshot.docs.length} old images');
    } catch (e) {
      print('Error in cleanupOldImages: $e');
    }
  }

  /// Track storage usage
  Future<void> _updateStorageStats(double sizeChangeKB) async {
    try {
      final statsRef = _firestore.collection('app_stats').doc('storage');

      // Use transactions to safely update the counter
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(statsRef);

        if (snapshot.exists) {
          double currentSizeKB = snapshot.data()?['totalSizeKB'] ?? 0;
          double newSizeKB = currentSizeKB + sizeChangeKB;

          transaction.update(statsRef, {
            'totalSizeKB': newSizeKB,
            'totalSizeMB': newSizeKB / 1024,
            'lastUpdated': FieldValue.serverTimestamp(),
            'imageCount': FieldValue.increment(sizeChangeKB > 0 ? 1 : -1),
          });
        } else {
          // First time creating the stats document
          transaction.set(statsRef, {
            'totalSizeKB': sizeChangeKB > 0 ? sizeChangeKB : 0,
            'totalSizeMB': sizeChangeKB > 0 ? sizeChangeKB / 1024 : 0,
            'lastUpdated': FieldValue.serverTimestamp(),
            'imageCount': sizeChangeKB > 0 ? 1 : 0,
          });
        }
      });
    } catch (e) {
      print('Error updating storage stats: $e');
      // Don't rethrow - this is a non-critical operation
    }
  }

  /// Get current storage usage
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final snapshot = await _firestore.collection('app_stats').doc('storage').get();

      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      } else {
        return {
          'totalSizeKB': 0,
          'totalSizeMB': 0,
          'imageCount': 0,
          'lastUpdated': Timestamp.now(),
        };
      }
    } catch (e) {
      print('Error getting storage stats: $e');
      return {
        'totalSizeKB': 0,
        'totalSizeMB': 0,
        'imageCount': 0,
        'error': e.toString(),
      };
    }
  }

  /// Delete all images created by a specific user
  Future<void> deleteAllUserImages(String userId) async {
    try {
      // Query all images by this user
      final querySnapshot = await _firestore
          .collection('ai_images')
          .where('userId', isEqualTo: userId)
          .get();

      // Delete each image
      for (var doc in querySnapshot.docs) {
        await deleteAiImage(doc.id);
      }

      print('Deleted ${querySnapshot.docs.length} images for user $userId');
    } catch (e) {
      print('Error deleting user images: $e');
      rethrow;
    }
  }

  Future<void> cleanupDeletedUserImages() async {
    try {
      // Query for all images
      final imagesSnapshot = await _firestore.collection('ai_images').get();

      for (var doc in imagesSnapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;

        // Check if the user still exists
        if (userId != null) {
          final userDoc = await _firestore.collection('users').doc(userId).get();

          // If user doesn't exist, delete the image
          if (!userDoc.exists) {
            await deleteAiImage(doc.id);
          }
        }
      }

      print('Cleaned up images from deleted users');
    } catch (e) {
      print('Error cleaning up images from deleted users: $e');
    }
  }

  /// Schedule cleanup task
  Future<void> scheduleCleanupIfNeeded() async {
    // Get the last cleanup time
    final prefs = _firestore.collection('app_stats').doc('cleanup');
    final snapshot = await prefs.get();

    bool shouldCleanup = true;

    if (snapshot.exists) {
      final data = snapshot.data();
      if (data != null && data['lastCleanup'] != null) {
        final lastCleanup = (data['lastCleanup'] as Timestamp).toDate();
        final daysSinceLastCleanup = DateTime.now().difference(lastCleanup).inDays;

        // Only cleanup once a week
        shouldCleanup = daysSinceLastCleanup >= 7;
      }
    }

    if (shouldCleanup) {
      await cleanupOldImages();
      await prefs.set({
        'lastCleanup': FieldValue.serverTimestamp(),
        'cleanupCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    }
  }

  /// Helper method to fix existing images
  Future<void> fixExistingImages() async {
    // Get all images with OpenAI URLs
    final snapshot = await _firestore
        .collection('ai_images')
        .get();

    int fixed = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final imageUrl = data['imageUrl'] as String;
      final userId = data['userId'] as String;

      // Check if URL is an OpenAI URL (they contain 'oaidalleapiprodscus')
      if (imageUrl.contains('oaidalleapiprodscus')) {
        try {
          // Try to download and re-upload the image
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            // Image still accessible, let's fix it
            final bytes = response.bodyBytes;
            final String fileId = const Uuid().v4();

            // Create compressed versions
            final thumbnailUrl = await _uploadCompressedImage(
                bytes,
                userId,
                fileId,
                thumbnailMaxSize,
                'thumbnail'
            );

            final detailUrl = await _uploadCompressedImage(
                bytes,
                userId,
                fileId,
                detailMaxSize,
                'detail'
            );

            // Calculate image size
            final sizeKB = bytes.length / 1024;

            // Update document with new URLs
            await _firestore
                .collection('ai_images')
                .doc(doc.id)
                .update({
              'imageUrl': detailUrl,
              'thumbnailUrl': thumbnailUrl,
              'detailUrl': detailUrl,
              'sizeKB': sizeKB.toStringAsFixed(2),
            });

            fixed++;
            print('Fixed image: ${doc.id}');

            // Update storage stats
            await _updateStorageStats(sizeKB);
          } else {
            print('Image URL expired and cannot be recovered: ${doc.id}');
            // Mark as expired in Firestore
            await _firestore
                .collection('ai_images')
                .doc(doc.id)
                .update({'imageExpired': true});
          }
        } catch (e) {
          print('Error fixing image ${doc.id}: $e');
        }
      }
    }

    print('Fixed $fixed images');
  }
}