import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  UserProfile? _userProfile;
  bool _isLoading = false;
  bool _isDeletingAccount = false;
  String? _deleteError;
  String? _lastFetchedUserId; // last user ID
  Map<String, UserProfile> _profileCache = {};
  Map<String, DateTime> _lastFetchTime = {};
  final Duration _cacheDuration = Duration(minutes: 5); // Cache expiration time

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isDeletingAccount => _isDeletingAccount;
  String? get deleteError => _deleteError;
  String? get lastFetchedUserId => _lastFetchedUserId;
  String? get profileImageUrl => _userProfile?.profileImageUrl;

  // Check if cache is valid for user
  bool _isCacheValid(String userId) {
    if (!_profileCache.containsKey(userId)) return false;

    final lastFetch = _lastFetchTime[userId];
    if (lastFetch == null) return false;

    final now = DateTime.now();
    return now.difference(lastFetch) < _cacheDuration;
  }

  // Clear cache for a specific user
  void invalidateCache(String userId) {
    print('Invalidating cache for user: $userId');
    _profileCache.remove(userId);
    _lastFetchTime.remove(userId);
  }

  // fetch user profile with caching
  Future<UserProfile?> fetchUserProfile(String userId) async {
    print('Fetching profile for userId: $userId');
    _lastFetchedUserId = userId;

    // Skip if already loaded this profile
    if (_isLoading && _userProfile?.id == userId) {
      print('Already loading profile for $userId, skipping duplicate request');
      return _userProfile;
    }

    // Return cached profile if available and valid
    if (_isCacheValid(userId)) {
      print('Using cached profile for $userId');
      _userProfile = _profileCache[userId];
      notifyListeners();
      return _userProfile;
    }

    // Otherwise, fetch from Firestore
    _isLoading = true;
    notifyListeners();

    try {
      print('Fetching profile from Firestore for $userId');
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        print('Profile document found for $userId');

        _userProfile = UserProfile(
          id: userId,
          name: data['name'],
          gender: data['gender'],
          age: data['age'],
          location: data['location'],
          bio: data['bio'],
          profileImageUrl: data['profileImageUrl'],
        );

        // Update cache
        _profileCache[userId] = _userProfile!;
        _lastFetchTime[userId] = DateTime.now();

        print('Profile loaded and cached for $userId');
      } else {
        print('No profile document found for $userId in Firestore');
        // Try to create a default profile since document doesn't exist
        await _createDefaultProfile(userId);
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      _userProfile = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _userProfile;
  }

  // Create a default profile if none exists
  Future<void> _createDefaultProfile(String userId) async {
    try {
      print('Attempting to create default profile for $userId');

      // Check if we already have a default profile in memory
      if (_userProfile != null && _userProfile!.id == userId) {
        print('Default profile already exists in memory');
        return;
      }

      // Create a default profile
      _userProfile = UserProfile(
        id: userId,
        name: 'User',
        gender: null,
        age: null,
        location: '',
        bio: '',
        profileImageUrl: null,
      );

      // Save to Firestore
      final userMap = {
        'id': userId,
        'name': 'User',
        'email': '',
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
        'bio': '',
        'location': '',
        'gender': null,
        'age': null,
        'profileImageUrl': null,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set(userMap);

      // Update cache
      _profileCache[userId] = _userProfile!;
      _lastFetchTime[userId] = DateTime.now();

      print('Default profile created and saved for $userId');
    } catch (e) {
      print('Error creating default profile: $e');
    }
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      print('Updating profile for $userId with data: $data');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(data);

      // Invalidate cache to force a refresh
      invalidateCache(userId);

      // Refetch the profile
      await fetchUserProfile(userId);

      print('Profile updated successfully for $userId');
    } catch (e) {
      print('Error updating profile: $e');
      rethrow; // Propagate error to UI
    }
  }

  // Upload new profile image
  Future<void> uploadProfileImage(File imageFile, String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('Uploading profile image for $userId');

      String? uploadedImageUrl = await _profileService.uploadProfileImage(imageFile, userId);

      // Update the profile with the new image URL
      if (uploadedImageUrl != null) {
        // If userProfile is null or doesn't match the userId, fetch it first
        if (_userProfile == null || _userProfile!.id != userId) {
          await fetchUserProfile(userId);
        }

        if (_userProfile != null) {
          _userProfile!.profileImageUrl = uploadedImageUrl;

          // Update Firestore with new image URL
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'profileImageUrl': uploadedImageUrl});

          // Update cache
          if (_profileCache.containsKey(userId)) {
            _profileCache[userId] = _userProfile!;
          }

          print('Profile image updated successfully for $userId');
        }
      }
    } catch (e) {
      print('Error uploading profile image: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile and notify listeners
  Future<void> updateUserProfile(String name, String bio, String location,
      {String? gender, String? age}) async {
    if (_userProfile != null) {
      final userId = _userProfile!.id!;
      print('Updating user profile for $userId');

      // Create updated profile with current values
      _userProfile = UserProfile(
        id: userId,
        name: name,
        gender: gender ?? _userProfile!.gender,
        age: age ?? _userProfile!.age,
        location: location,
        bio: bio,
        profileImageUrl: _userProfile!.profileImageUrl,
      );

      // Update profile in Firestore
      await _profileService.updateUserProfile(_userProfile!);

      // Update cache
      if (_profileCache.containsKey(userId)) {
        _profileCache[userId] = _userProfile!;
      }

      print('User profile updated successfully for $userId');

      notifyListeners();
    } else {
      print('Error: Cannot update profile - no active profile');
    }
  }

  // Delete user account and all associated data
  Future<bool> deleteUserAccount(String userId) async {
    if (_userProfile == null || _userProfile!.id != userId) {
      _deleteError = 'User profile not found';
      notifyListeners();
      return false;
    }

    _isDeletingAccount = true;
    _deleteError = null;
    notifyListeners();

    try {
      print('Deleting user account for $userId');

      // Use the ProfileService to handle all deletion steps
      await _profileService.completeAccountDeletion(userId);

      // Clear cache for this user
      invalidateCache(userId);

      _isDeletingAccount = false;
      notifyListeners();

      print('User account deleted successfully for $userId');
      return true;
    } catch (e) {
      print('Error deleting user account: $e');
      _deleteError = e.toString();
      _isDeletingAccount = false;
      notifyListeners();
      return false;
    }
  }

  // Force refresh a profile
  Future<UserProfile?> forceRefreshProfile(String userId) async {
    print('Force refreshing profile for $userId');
    // Clear cache for this user
    invalidateCache(userId);

    // Fetch fresh data
    return await fetchUserProfile(userId);
  }

  // Get profile status info (for debugging)
  String getProfileStatus() {
    return 'Profile Status: '
        'isLoading=$_isLoading, '
        'hasProfile=${_userProfile != null}, '
        'profileId=${_userProfile?.id}, '
        'lastFetchedId=$_lastFetchedUserId, '
        'cacheSize=${_profileCache.length}';
  }
}