import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  UserProfile? _userProfile;
  String? profileImageUrl; // Remove `final` modifier here to allow updates
  bool _isLoading = false;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;

  // Fetch user profile and notify listeners
  Future<void> fetchUserProfile(String userId) async {
    _isLoading = true;
    notifyListeners();
    _userProfile = await _profileService.getUserProfile(userId);
    profileImageUrl = _userProfile?.profileImageUrl;
    _isLoading = false;
    notifyListeners();
  }

  // Upload new profile image
  Future<void> uploadProfileImage(File imageFile, String userId) async {
    _isLoading = true;
    notifyListeners();
    profileImageUrl = await _profileService.uploadProfileImage(imageFile, userId);
    _userProfile?.profileImageUrl = profileImageUrl;
    _isLoading = false;
    notifyListeners();
  }

  // Update user profile and notify listeners
  Future<void> updateUserProfile(String name, String bio, String location,
      {String? gender, String? age}) async {
    if (_userProfile != null) {
      _userProfile = UserProfile(
        id: _userProfile!.id,
        name: name,
        gender: gender,
        age: age,
        location: location,
        bio: bio,
        profileImageUrl: profileImageUrl,
      );
      await _profileService.updateUserProfile(_userProfile!);
      notifyListeners();
    }
  }
}
