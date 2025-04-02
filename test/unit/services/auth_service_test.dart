import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:numinous_ways/services/auth_service.dart';

// Custom mock for FirebaseAuth errors
class MockFirebaseAuthWithError extends MockFirebaseAuth {
  final String errorCode;
  final String errorMessage;

  MockFirebaseAuthWithError({
    required this.errorCode,
    this.errorMessage = 'Mock error message',
  });

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw FirebaseAuthException(
      code: errorCode,
      message: errorMessage,
    );
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    if (errorCode.isNotEmpty) {
      throw FirebaseAuthException(
        code: errorCode,
        message: errorMessage,
      );
    }
    return;
  }
}

// Manual mocks for Google Sign In
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}
class MockGoogleSignInAuthentication extends Mock implements GoogleSignInAuthentication {}

void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockFirebaseAuth mockFirebaseAuth;

    setUp(() {
      // Initialize mock FirebaseAuth
      mockFirebaseAuth = MockFirebaseAuth();

      // Setup AuthService with mock
      authService = AuthService(
        authInstance: mockFirebaseAuth,
      );
    });

    group('signInWithEmailPassword', () {
      test('returns User when successful', () async {
        // Arrange
        final mockUser = MockUser(
          email: 'test@test.com',
          isEmailVerified: true,
        );
        mockFirebaseAuth = MockFirebaseAuth(mockUser: mockUser);
        authService = AuthService(authInstance: mockFirebaseAuth);
        // Act
        final user = await authService.signInWithEmailPassword('test@test.com', 'password');
        // Assert
        expect(user, isNotNull);
        expect(user?.email, 'test@test.com');
        expect(user?.emailVerified, true);
      });

      test('throws correct error for user-not-found', () async {
        // Arrange
        mockFirebaseAuth = MockFirebaseAuthWithError(
          errorCode: 'user-not-found',
        );
        authService = AuthService(authInstance: mockFirebaseAuth);

        // Act & Assert
        expect(
              () => authService.signInWithEmailPassword('unknown@test.com', 'password'),
          throwsA('No account found for this email. Please check and try again.'),
        );
      });

      test('throws correct error for wrong-password', () async {
        // Arrange
        mockFirebaseAuth = MockFirebaseAuthWithError(
          errorCode: 'wrong-password',
        );
        authService = AuthService(authInstance: mockFirebaseAuth);

        // Act & Assert
        expect(
              () => authService.signInWithEmailPassword('test@test.com', 'wrongpassword'),
          throwsA('Incorrect password. Please try again.'),
        );
      });

      test('throws correct error for invalid-email', () async {
        // Arrange
        mockFirebaseAuth = MockFirebaseAuthWithError(
          errorCode: 'invalid-email',
        );
        authService = AuthService(authInstance: mockFirebaseAuth);

        // Act & Assert
        expect(
              () => authService.signInWithEmailPassword('invalid-email', 'password'),
          throwsA('Invalid email format. Please enter a valid email.'),
        );
      });
    });

    group('resetPassword', () {
      test('completes successfully with valid email', () async {
        // Act & Assert
        expect(
            authService.resetPassword('test@test.com'),
            completes
        );
      });

      test('throws correct error for user-not-found', () async {
        // Arrange
        mockFirebaseAuth = MockFirebaseAuthWithError(
          errorCode: 'user-not-found',
        );
        authService = AuthService(authInstance: mockFirebaseAuth);

        // Act & Assert
        expect(
              () => authService.resetPassword('unknown@test.com'),
          throwsA('No account found for this email. Please check and try again.'),
        );
      });
    });

    group('isEmailVerified', () {
      test('returns true when email is verified', () async {
        // Arrange
        final mockUser = MockUser(
          isEmailVerified: true,
        );
        mockFirebaseAuth = MockFirebaseAuth(
          mockUser: mockUser,
          signedIn: true,
        );
        authService = AuthService(authInstance: mockFirebaseAuth);

        // Act
        final isVerified = await authService.isEmailVerified();

        // Assert
        expect(isVerified, true);
      });

      test('returns false when email is not verified', () async {
        // Arrange
        final mockUser = MockUser(
          isEmailVerified: false,
        );
        mockFirebaseAuth = MockFirebaseAuth(
          mockUser: mockUser,
          signedIn: true,
        );
        authService = AuthService(authInstance: mockFirebaseAuth);

        // Act
        final isVerified = await authService.isEmailVerified();

        // Assert
        expect(isVerified, false);
      });

      test('returns false when no user is signed in', () async {
        // Arrange
        mockFirebaseAuth = MockFirebaseAuth(signedIn: false);
        authService = AuthService(authInstance: mockFirebaseAuth);

        // Act
        final isVerified = await authService.isEmailVerified();

        // Assert
        expect(isVerified, false);
      });
    });

    // Additional test for sendVerificationEmail method
    test('sendVerificationEmail sends email when user is signed in', () async {
      // Arrange
      final mockUser = MockUser(
        email: 'test@test.com',
        isEmailVerified: false,
      );
      mockFirebaseAuth = MockFirebaseAuth(
        mockUser: mockUser,
        signedIn: true,
      );
      authService = AuthService(authInstance: mockFirebaseAuth);

      // Act & Assert
      expect(authService.sendVerificationEmail(), completes);
    });
  });
}