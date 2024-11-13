class UserProfile {
  String? id;
  String? name;
  String? gender;
  String? age;
  String? location;
  String? bio;
  String? profileImageUrl; // Remove `final` here

  UserProfile({
    this.id,
    this.name,
    this.gender,
    this.age,
    this.location,
    this.bio,
    this.profileImageUrl,
  });

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      id: data['id'],
      name: data['name'],
      gender: data['gender'],
      age: data['age'],
      location: data['location'],
      bio: data['bio'],
      profileImageUrl: data['profileImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'age': age,
      'location': location,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
    };
  }
}
