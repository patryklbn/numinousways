import 'package:cloud_firestore/cloud_firestore.dart';

class Venue {
  final String id;
  final String name;
  final String description;
  final List<String> images;

  Venue({
    required this.id,
    required this.name,
    required this.description,
    required this.images,
  });

  // Factory constructor to create Venue from Firestore DocumentSnapshot
  factory Venue.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Venue(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      images: List<String>.from(data['images'] ?? []),
    );
  }

  // Method to convert Venue to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'images': images,
    };
  }
}
