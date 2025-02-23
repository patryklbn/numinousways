// comment.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  String id;
  String userId;
  String content;
  Timestamp createdAt;
  int likesCount;
  bool isLiked; // Indicates if the current user has liked this comment

  Comment({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.likesCount = 0,
    this.isLiked = false,
  });

  factory Comment.fromDocument(DocumentSnapshot doc, {required String currentUserId}) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Safely handle the likes field - it might not exist in older documents
    bool liked = false;
    List<dynamic> likes = [];

    try {
      // First check if the field exists before trying to access it
      if (data.containsKey('likes')) {
        likes = List<dynamic>.from(data['likes'] ?? []);
        liked = likes.contains(currentUserId);
      }
    } catch (e) {
      print('Error processing likes for comment ${doc.id}: $e');
      // Default to not liked if there's an error
      liked = false;
    }

    return Comment(
      id: doc.id,
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      likesCount: data.containsKey('likesCount') ? data['likesCount'] : 0,
      isLiked: liked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'content': content,
      'createdAt': createdAt,
      'likesCount': likesCount,
      // 'likes' is not stored in the model as it's user-specific
    };
  }
}