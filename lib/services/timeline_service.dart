import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/post.dart';
import '../models/comment.dart';
import 'package:path/path.dart' as path;

class TimelineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
      'likes': [],
    });
  }

  /// Get post by its ID
  Future<Post> getPostById(String postId, String currentUserId) async {
    DocumentSnapshot doc = await _firestore.collection('posts').doc(postId).get();
    return Post.fromDocument(doc, currentUserId: currentUserId);
  }

  /// Delete a post and its associated image
  Future<void> deletePost(String postId) async {
    try {
      DocumentReference postRef = _firestore.collection('posts').doc(postId);

      // Get the post data to check for image
      DocumentSnapshot postSnapshot = await postRef.get();
      Map<String, dynamic>? postData = postSnapshot.data() as Map<String, dynamic>?;

      // Get all comments to check for images
      QuerySnapshot commentsSnapshot = await postRef.collection('comments').get();


      WriteBatch batch = _firestore.batch();

      // Delete all comments and their images
      for (QueryDocumentSnapshot commentDoc in commentsSnapshot.docs) {
        Map<String, dynamic> commentData = commentDoc.data() as Map<String, dynamic>;

        // Delete comment image if it exists
        if (commentData['imageUrl'] != null && commentData['imageUrl'].toString().isNotEmpty) {
          try {
            // Convert the image URL to a storage reference and delete
            await _deleteImageFromStorage(commentData['imageUrl']);
          } catch (e) {
            print('Error deleting comment image: $e');
            // Continue with the deletion process even if image deletion fails
          }
        }

        // Add comment deletion to batch
        batch.delete(commentDoc.reference);
      }

      // Delete post image if it exists
      if (postData != null && postData['imageUrl'] != null && postData['imageUrl'].toString().isNotEmpty) {
        try {
          await _deleteImageFromStorage(postData['imageUrl']);
        } catch (e) {
          print('Error deleting post image: $e');
        }
      }

      // Add post deletion to batch
      batch.delete(postRef);

      // Commit all deletions
      await batch.commit();

    } catch (e) {
      print('Error in deletePost: $e');
      throw e;
    }
  }

  /// Helper method to delete an image from Firebase Storage
  Future<void> _deleteImageFromStorage(String imageUrl) async {
    try {
      // Extract the path from the URL
      // Parse the URL to get the storage path
      Uri uri = Uri.parse(imageUrl);
      String path = Uri.decodeComponent(uri.path);


      int startIndex = path.indexOf('/o/') + 3;
      String storagePath = path.substring(startIndex);

      // Create a reference to the file and delete it
      await _storage.ref().child(storagePath).delete();
      print('Successfully deleted image from storage: $storagePath');
    } catch (e) {
      print('Error parsing or deleting image: $e');
      throw e;
    }
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
        'imageUrl': imageUrl,
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
          imageUrl: data['imageUrl'],
          likesCount: data['likesCount'] ?? 0,
          isLiked: likes.contains(currentUserId),
          createdAt: data['createdAt'] ?? Timestamp.now(),
        );
      }).toList();
    });
  }


  Future<String?> uploadCommentImage(File imageFile, String postId) async {
    try {

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

  /// Delete a comment and its associated image
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      // Reference to the comment
      DocumentReference commentRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId);

      // Get the comment data to check for image
      DocumentSnapshot commentSnapshot = await commentRef.get();
      if (!commentSnapshot.exists) {
        throw Exception('Comment not found');
      }

      Map<String, dynamic> commentData = commentSnapshot.data() as Map<String, dynamic>;

      // Start a transaction to ensure both operations complete together
      await _firestore.runTransaction((transaction) async {
        // Delete the comment image if it exists
        if (commentData['imageUrl'] != null && commentData['imageUrl'].toString().isNotEmpty) {
          try {
            await _deleteImageFromStorage(commentData['imageUrl']);
          } catch (e) {
            print('Error deleting comment image: $e');
            // Continue with comment deletion even if image deletion fails
          }
        }

        // Delete the comment from Firestore
        transaction.delete(commentRef);

        // Update the post's comment count
        DocumentReference postRef = _firestore.collection('posts').doc(postId);
        transaction.update(postRef, {
          'commentsCount': FieldValue.increment(-1)
        });
      });

    } catch (e) {
      print('Error deleting comment: $e');
      throw Exception('Error deleting comment: $e');
    }
  }


  /// Toggle like status on a comment
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
          // If likesCount doesn't exist, creatyer it with the length of likes
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