import 'package:cloud_firestore/cloud_firestore.dart';

class Facilitator {
  final String id;
  final String name;
  final String role;
  final String photoUrl;

  Facilitator({
    required this.id,
    required this.name,
    required this.role,
    required this.photoUrl,
  });

  // Factory constructor to create Facilitator from Firestore DocumentSnapshot
  factory Facilitator.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Facilitator(
      id: doc.id,
      name: data['name'] ?? '',
      role: data['role'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
    );
  }

  // Method to convert Facilitator to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'photoUrl': photoUrl,
    };
  }
}
