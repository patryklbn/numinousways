import 'package:cloud_firestore/cloud_firestore.dart';

class SocialMediaLink {
  final String platform;
  final String url;

  SocialMediaLink({required this.platform, required this.url});

  factory SocialMediaLink.fromMap(Map<String, dynamic> data) {
    return SocialMediaLink(
      platform: data['platform'] ?? '',
      url: data['url'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'platform': platform,
      'url': url,
    };
  }
}

class Facilitator {
  final String id;
  final String name;
  final String role;
  final String photoUrl;
  final String? description;
  final List<SocialMediaLink>? socialMediaLinks;

  Facilitator({
    required this.id,
    required this.name,
    required this.role,
    required this.photoUrl,
    this.description,
    this.socialMediaLinks,
  });

  factory Facilitator.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    List<SocialMediaLink>? socialLinks;
    if (data['socialMediaLinks'] != null) {
      socialLinks = (data['socialMediaLinks'] as List)
          .map((e) => SocialMediaLink.fromMap(e as Map<String, dynamic>))
          .toList();
    }
    return Facilitator(
      id: doc.id,
      name: data['name'] ?? '',
      role: data['role'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      description: data['description'],
      socialMediaLinks: socialLinks,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'photoUrl': photoUrl,
      if (description != null) 'description': description,
      if (socialMediaLinks != null)
        'socialMediaLinks': socialMediaLinks!.map((e) => e.toMap()).toList(),
    };
  }
}
