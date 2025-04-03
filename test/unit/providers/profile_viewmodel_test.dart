import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:numinous_ways/models/user_profile.dart';

// Mock implementation for testing
class TestProfileViewModel extends ChangeNotifier {
  UserProfile? _userProfile;
  bool _isLoading = false;
  bool _isDeletingAccount = false;
  String? _deleteError;
  Map<String, UserProfile> _profileCache = {}; // Cache profiles by userId
  Map<String, DateTime> _lastFetchTime = {}; // Track when profiles were last fetched
  final Duration _cacheDuration = Duration(minutes: 5); // Cache expiration time

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isDeletingAccount => _isDeletingAccount;
  String? get deleteError => _deleteError;
  String? get profileImageUrl => _userProfile?.profileImageUrl;

  // Check if cache is valid for user
  bool isCacheValid(String userId) {
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

  // Test helper method to set up cache
  void setupCache(String userId, UserProfile profile, [DateTime? fetchTime]) {
    _profileCache[userId] = profile;
    _lastFetchTime[userId] = fetchTime ?? DateTime.now();
  }

  // Test helper method to get cached profile
  UserProfile? getCachedProfile(String userId) {
    return _profileCache[userId];
  }

  // Test helper method to set user profile
  void setUserProfile(UserProfile profile) {
    _userProfile = profile;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProfileViewModel Basic Tests', () {
    late TestProfileViewModel viewModel;

    setUp(() {
      viewModel = TestProfileViewModel();
    });

    test('Initial state should be correct', () {
      expect(viewModel.userProfile, isNull);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.isDeletingAccount, isFalse);
      expect(viewModel.deleteError, isNull);
      expect(viewModel.profileImageUrl, isNull);
    });

    test('profileImageUrl getter should return the correct URL', () {
      // Create test profile
      final testProfile = UserProfile(
        id: 'test-id',
        name: 'Test User',
        profileImageUrl: 'https://example.com/image.jpg',
      );

      // Set the profile
      viewModel.setUserProfile(testProfile);

      // Test the getter
      expect(viewModel.profileImageUrl, equals('https://example.com/image.jpg'));
    });

    test('Cache invalidation should work correctly', () {
      final userId = 'test-user';

      // Set up the cache with a test profile
      final testProfile = UserProfile(
        id: userId,
        name: 'Test User',
      );

      viewModel.setupCache(userId, testProfile);

      // Verify cache is set up properly
      expect(viewModel.getCachedProfile(userId), isNotNull);

      // Now invalidate the cache
      viewModel.invalidateCache(userId);

      // Verify cache is cleared
      expect(viewModel.getCachedProfile(userId), isNull);
    });

    test('Cache duration should expire after set time', () {
      final userId = 'time-test-user';

      // Set up cache with an expired timestamp
      final testProfile = UserProfile(
        id: userId,
        name: 'Test User',
      );

      // Set cache with a timestamp from 10 minutes ago
      viewModel.setupCache(
          userId,
          testProfile,
          DateTime.now().subtract(Duration(minutes: 10))
      );

      // Check if cache is valid
      expect(viewModel.isCacheValid(userId), isFalse);
    });

    test('Cache should be valid within duration', () {
      final userId = 'valid-cache-user';

      // Set up cache with a recent timestamp
      final testProfile = UserProfile(
        id: userId,
        name: 'Test User',
      );

      // Set cache with a timestamp from 1 minute ago
      viewModel.setupCache(
          userId,
          testProfile,
          DateTime.now().subtract(Duration(minutes: 1))
      );

      // Check if cache is valid
      expect(viewModel.isCacheValid(userId), isTrue);
    });
  });
}