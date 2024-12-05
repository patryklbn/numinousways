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
  bool isLiked;

  Post({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
  });

  factory Post.fromDocument(DocumentSnapshot doc, {required String currentUserId}) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
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

  Post copyWith({int? likesCount, bool? isLiked}) {
    return Post(
      id: this.id,
      userId: this.userId,
      content: this.content,
      imageUrl: this.imageUrl,
      createdAt: this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
