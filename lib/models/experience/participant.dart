import 'package:cloud_firestore/cloud_firestore.dart';

class Participant {
  final String userId;
  final String role;
  final bool shareBio;
  final String? detailedBio;
  final bool meqConsent;

  // About Me fields
  final String name;
  final String aboutYourself;
  final String nickname;
  final String pronouns;
  final String work;
  final String hobbies;
  final String psychedelicExperience;
  final String additionalInfo;
  final String favoriteAnimal;
  final String earliestMemory;
  final String somethingYouLove;
  final String somethingDifficult;

  final String? photoUrl;

  Participant({
    required this.userId,
    required this.role,
    required this.shareBio,
    this.detailedBio,
    this.meqConsent = false,
    this.name = '',
    this.aboutYourself = '',
    this.nickname = '',
    this.pronouns = '',
    this.work = '',
    this.hobbies = '',
    this.psychedelicExperience = '',
    this.additionalInfo = '',
    this.favoriteAnimal = '',
    this.earliestMemory = '',
    this.somethingYouLove = '',
    this.somethingDifficult = '',
    this.photoUrl,
  });

  factory Participant.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Participant(
      userId: doc.id,
      role: data['role'] ?? 'member',
      shareBio: data['shareBio'] ?? false,
      detailedBio: data['detailedBio'],
      meqConsent: data['meqConsent'] ?? false,
      name: data['name'] ?? '',
      aboutYourself: data['aboutYourself'] ?? '',
      nickname: data['nickname'] ?? '',
      pronouns: data['pronouns'] ?? '',
      work: data['work'] ?? '',
      hobbies: data['hobbies'] ?? '',
      psychedelicExperience: data['psychedelicExperience'] ?? '',
      additionalInfo: data['additionalInfo'] ?? '',
      favoriteAnimal: data['favoriteAnimal'] ?? '',
      earliestMemory: data['earliestMemory'] ?? '',
      somethingYouLove: data['somethingYouLove'] ?? '',
      somethingDifficult: data['somethingDifficult'] ?? '',
      photoUrl: data['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'shareBio': shareBio,
      if (detailedBio != null) 'detailedBio': detailedBio,
      'meqConsent': meqConsent,
      'name': name,
      'aboutYourself': aboutYourself,
      'nickname': nickname,
      'pronouns': pronouns,
      'work': work,
      'hobbies': hobbies,
      'psychedelicExperience': psychedelicExperience,
      'additionalInfo': additionalInfo,
      'favoriteAnimal': favoriteAnimal,
      'earliestMemory': earliestMemory,
      'somethingYouLove': somethingYouLove,
      'somethingDifficult': somethingDifficult,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }

  // Here is the copyWith method
  Participant copyWith({
    bool? shareBio,
    String? detailedBio,
    bool? meqConsent,
    String? name,
    String? aboutYourself,
    String? nickname,
    String? pronouns,
    String? work,
    String? hobbies,
    String? psychedelicExperience,
    String? additionalInfo,
    String? favoriteAnimal,
    String? earliestMemory,
    String? somethingYouLove,
    String? somethingDifficult,
    String? photoUrl,
  }) {
    return Participant(
      userId: userId,  // typically unchanged
      role: role,      // typically unchanged
      shareBio: shareBio ?? this.shareBio,
      detailedBio: detailedBio ?? this.detailedBio,
      meqConsent: meqConsent ?? this.meqConsent,
      name: name ?? this.name,
      aboutYourself: aboutYourself ?? this.aboutYourself,
      nickname: nickname ?? this.nickname,
      pronouns: pronouns ?? this.pronouns,
      work: work ?? this.work,
      hobbies: hobbies ?? this.hobbies,
      psychedelicExperience: psychedelicExperience ?? this.psychedelicExperience,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      favoriteAnimal: favoriteAnimal ?? this.favoriteAnimal,
      earliestMemory: earliestMemory ?? this.earliestMemory,
      somethingYouLove: somethingYouLove ?? this.somethingYouLove,
      somethingDifficult: somethingDifficult ?? this.somethingDifficult,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
