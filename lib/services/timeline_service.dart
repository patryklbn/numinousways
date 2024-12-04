// timeline_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';
import '../models/comment.dart';

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

  // -------------------------
  // Comment-Related Methods
  // -------------------------

  /// Add a comment to a post
  Future<void> addComment(
      String postId, String content, String currentUserId) async {
    DocumentReference postRef = _firestore.collection('posts').doc(postId);

    // Add the comment to the 'comments' subcollection
    await postRef.collection('comments').add({
      'userId': currentUserId,
      'content': content,
      'createdAt': Timestamp.now(),
      'likesCount': 0,
      'likes': [], // Initialize likes as empty array
    });

    // Increment the commentsCount in the post document
    await postRef.update({
      'commentsCount': FieldValue.increment(1),
    });
  }

  /// Get comments for a post
  Stream<List<Comment>> getComments(String postId, String currentUserId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Comment.fromDocument(doc, currentUserId: currentUserId))
        .toList());
  }

  /// Toggle like status on a comment
  Future<void> toggleLikeOnComment(
      String postId, String commentId, String currentUserId) async {
    DocumentReference commentRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);

    DocumentSnapshot commentSnapshot = await commentRef.get();

    if (commentSnapshot.exists) {
      List<dynamic> likes = commentSnapshot.get('likes') ?? [];
      int likesCount = commentSnapshot.get('likesCount') ?? 0;

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
  }
}
