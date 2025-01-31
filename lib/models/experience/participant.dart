import 'package:cloud_firestore/cloud_firestore.dart';

class Participant {
  final String userId;        // doc ID in participants subcollection
  final String role;          // "member", "facilitator", "admin", ...
  final bool shareBio;        // does user allow their bio to be visible?
  final String? detailedBio;  // the user's extended/long bio
  final bool meqConsent;      // user consent for MEQ forms, if needed

  // Add more fields if you like: e.g. mushroomOrdered, etc.

  Participant({
    required this.userId,
    required this.role,
    required this.shareBio,
    this.detailedBio,
    this.meqConsent = false,
  });

  factory Participant.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Participant(
      userId: doc.id,
      role: data['role'] ?? 'member',
      shareBio: data['shareBio'] ?? false,
      detailedBio: data['detailedBio'],
      meqConsent: data['meqConsent'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'shareBio': shareBio,
      if (detailedBio != null) 'detailedBio': detailedBio,
      'meqConsent': meqConsent,
    };
  }
}
