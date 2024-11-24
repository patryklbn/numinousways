// post.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  String id;
  String userId;
  String content;
  String? imageUrl;
  Timestamp createdAt;
  int likesCount;
  int commentsCount;
  bool isLiked; // New property

  Post({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false, // Default value
  });

  factory Post.fromDocument(DocumentSnapshot doc, {required String currentUserId}) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    // Determine if the current user has liked the post
    bool liked = false;
    if (data['likes'] != null && data['likes'] is List) {
      liked = (data['likes'] as List).contains(currentUserId);
    }
    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      isLiked: liked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      // 'isLiked' is not stored in Firestore as it's user-specific
    };
  }
}
