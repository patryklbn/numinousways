import 'package:cloud_firestore/cloud_firestore.dart';

class Venue {
  final String id;
  final String name;
  final String description;
  final List<String> detailedDescription;
  final List<String> images;

  Venue({
    required this.id,
    required this.name,
    required this.description,
    required this.detailedDescription,
    required this.images,
  });

  // Factory constructor to create Venue from Firestore DocumentSnapshot
  factory Venue.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Venue(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      detailedDescription: List<String>.from(data['detailedDescription'] ?? []),
      images: List<String>.from(data['images'] ?? []),
    );
  }

  // Method to convert Venue to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'detailedDescription': detailedDescription,
      'images': images,
    };
  }
}
