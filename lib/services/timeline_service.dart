import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/post.dart';
import '../models/comment.dart';
import 'package:path/path.dart' as path;

class TimelineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // -------------------------
  // Post-Related Methods
  // -------------------------

  /// Fetch posts with isLiked property
  Stream<List<Post>> getPosts(String currentUserId) {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Post.fromDocument(doc, currentUserId: currentUserId))
        .toList());
  }

  /// Toggle like status
  Future<void> toggleLike(String postId, String currentUserId) async {
    DocumentReference postRef = _firestore.collection('posts').doc(postId);
    DocumentSnapshot postSnapshot = await postRef.get();

    if (postSnapshot.exists) {
      List<dynamic> likes = postSnapshot.get('likes') ?? [];
      int likesCount = postSnapshot.get('likesCount') ?? 0;

      if (likes.contains(currentUserId)) {
        // User has already liked the post, so unlike it
        await postRef.update({
          'likes': FieldValue.arrayRemove([currentUserId]),
          'likesCount': likesCount > 0 ? likesCount - 1 : 0,
        });
      } else {
        // User has not liked the post, so like it
        await postRef.update({
          'likes': FieldValue.arrayUnion([currentUserId]),
          'likesCount': likesCount + 1,
        });
      }
    }
  }

  /// Create a new post
  Future<void> createPost(String content,
      {String? imageUrl, required String currentUserId}) async {
    await _firestore.collection('posts').add({
      'userId': currentUserId,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.now(),
      'likesCount': 0,
      'commentsCount': 0,
      'likes': [], // Initialize likes as empty array
    });
  }

  /// Get post by its ID
  Future<Post> getPostById(String postId, String currentUserId) async {
    DocumentSnapshot doc = await _firestore.collection('posts').doc(postId).get();
    return Post.fromDocument(doc, currentUserId: currentUserId);
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    DocumentReference postRef = _firestore.collection('posts').doc(postId);

    // Delete the post document and its comments
    WriteBatch batch = _firestore.batch();

    // Delete all comments associated with this post
    QuerySnapshot commentsSnapshot = await postRef.collection('comments').get();
    for (QueryDocumentSnapshot commentDoc in commentsSnapshot.docs) {
      batch.delete(commentDoc.reference);
    }

    // Delete the post itself
    batch.delete(postRef);

    // Commit the batch delete
    await batch.commit();
  }

  // -------------------------
  // Comment-Related Methods
  // -------------------------

  /// Add a comment to a post
  Future<void> addComment(String postId, String content, String userId, {String? imageUrl}) async {
    try {
      // Reference to the comments collection for this post
      final commentsRef = _firestore.collection('posts').doc(postId).collection('comments');

      // Create a new comment document
      await commentsRef.add({
        'userId': userId,
        'content': content,
        'imageUrl': imageUrl, // Add the image URL if available
        'likesCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update the comments count in the post document
      await _firestore.collection('posts').doc(postId).update({
        'commentsCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error adding comment: $e');
      throw e;
    }
  }

  /// Get comments for a post
  Stream<List<Comment>> getComments(String postId, String currentUserId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final likes = data['likes'] as List<dynamic>? ?? [];

        return Comment(
          id: doc.id,
          userId: data['userId'] ?? '',
          content: data['content'] ?? '',
          imageUrl: data['imageUrl'], // Add this line to get the image URL
          likesCount: data['likesCount'] ?? 0,
          isLiked: likes.contains(currentUserId),
          createdAt: data['createdAt'] ?? Timestamp.now(),
        );
      }).toList();
    });
  }

  // Add this method to upload comment images
  Future<String?> uploadCommentImage(File imageFile, String postId) async {
    try {
      // Compress the image first if you have a compression function
      // File compressedImage = await compressImage(imageFile);

      // Create a unique filename with timestamp
      final fileName = 'comment_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';

      // Reference to the storage path with postId and filename
      final storageRef = FirebaseStorage.instance.ref().child('comment_images/$postId/$fileName');

      // Upload the file
      await storageRef.putFile(imageFile);

      // Get the download URL
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading comment image: $e");
      return null;
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();
    } catch (e) {
      throw Exception('Error deleting comment: $e');
    }
  }


  /// Toggle like status on a comment
  /// Toggle like status on a comment - with improved error handling
  Future<void> toggleLikeOnComment(
      String postId, String commentId, String currentUserId) async {
    DocumentReference commentRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);

    try {
      DocumentSnapshot commentSnapshot = await commentRef.get();

      if (commentSnapshot.exists) {
        Map<String, dynamic> data = commentSnapshot.data() as Map<String, dynamic>;

        // Safely handle the likes field - it might not exist in older documents
        List<dynamic> likes = [];
        int likesCount = 0;

        // Check if likes field exists in the document
        if (data.containsKey('likes')) {
          likes = List<dynamic>.from(data['likes'] ?? []);
        }

        // Check if likesCount field exists
        if (data.containsKey('likesCount')) {
          likesCount = data['likesCount'];
        } else {
          // If likesCount doesn't exist, initialize it with the length of likes
          likesCount = likes.length;
        }

        if (likes.contains(currentUserId)) {
          // Unlike the comment
          await commentRef.update({
            'likes': FieldValue.arrayRemove([currentUserId]),
            'likesCount': likesCount > 0 ? likesCount - 1 : 0,
          });
        } else {
          // Like the comment
          await commentRef.update({
            'likes': FieldValue.arrayUnion([currentUserId]),
            'likesCount': likesCount + 1,
          });
        }
      }
    } catch (e) {
      print('Error toggling like on comment: $e');
      throw Exception('Failed to toggle like: $e');
    }
  }
}
