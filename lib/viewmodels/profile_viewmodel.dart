import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  UserProfile? _userProfile;
  bool _isLoading = false;
  Map<String, UserProfile> _profileCache = {}; // Cache profiles by userId
  Map<String, DateTime> _lastFetchTime = {}; // Track when profiles were last fetched
  final Duration _cacheDuration = Duration(minutes: 5); // Cache expiration time

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;

  // Fix for the profileImageUrl getter
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
    _profileCache.remove(userId);
    _lastFetchTime.remove(userId);
  }

  // Main method to fetch user profile with caching
  Future<void> fetchUserProfile(String userId) async {
    // Skip if we're already loading this profile
    if (_isLoading && _userProfile?.id == userId) return;

    // Return cached profile if available and valid
    if (_isCacheValid(userId)) {
      _userProfile = _profileCache[userId];
      notifyListeners();
      return;
    }

    // Otherwise, fetch from Firestore
    _isLoading = true;
    notifyListeners();

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
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
      } else {
        _userProfile = null;
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      _userProfile = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(data);

      // Invalidate cache to force a refresh
      invalidateCache(userId);

      // Refetch the profile
      await fetchUserProfile(userId);
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
      String? uploadedImageUrl = await _profileService.uploadProfileImage(imageFile, userId);

      // Update the profile with the new image URL
      if (_userProfile != null && uploadedImageUrl != null) {
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
      // Create updated profile with current values
      _userProfile = UserProfile(
        id: _userProfile!.id,
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
      if (_profileCache.containsKey(_userProfile!.id!)) {
        _profileCache[_userProfile!.id!] = _userProfile!;
      }

      notifyListeners();
    }
  }
}
