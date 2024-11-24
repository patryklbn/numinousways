// comment.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  String id;
  String userId;
  String content;
  Timestamp createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}
