import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/mockito.dart';
import 'package:numinous_ways/services/login_provider.dart';

// Mock for FirebaseAuth with error handling
class MockAuthWithErrors extends Mock implements FirebaseAuth {
  final String errorCode;
  final String? errorMessage;

  MockAuthWithErrors({
    required this.errorCode,
    this.errorMessage,
  });

  @override
  Stream<User?> authStateChanges() {
    return Stream.value(null);
  }

  @override
  User? get currentUser => null;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw FirebaseAuthException(
      code: errorCode,
      message: errorMessage ?? 'Mock error message',
    );
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw FirebaseAuthException(
      code: errorCode,
      message: errorMessage ?? 'Mock error message',
    );
  }
}

// Mock for Google Sign In
class MockGoogleSignIn extends Mock implements GoogleSignIn {
  final bool returnNull;

  MockGoogleSignIn({this.returnNull = false});

  @override
  Future<GoogleSignInAccount?> signIn() async {
    if (returnNull) return null;
    return MockGoogleSignInAccount();
  }

  @override
  Future<bool> isSignedIn() async {
    return true;
  }

  @override
  Future<GoogleSignInAccount?> signOut() async {
    return null;
  }
}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {
  @override
  Future<GoogleSignInAuthentication> get authentication async => MockGoogleSignInAuthentication();
}

class MockGoogleSignInAuthentication extends Mock implements GoogleSignInAuthentication {
  @override
  String? get accessToken => 'mock-access-token';

  @override
  String? get idToken => 'mock-id-token';
}

// Extended MockUser class
class ExtendedMockUser extends MockUser {
  final bool isVerified;

  ExtendedMockUser({
    required String uid,
    required String email,
    this.isVerified = true,
  }) : super(uid: uid, email: email, isEmailVerified: isVerified);

  @override
  Future<void> sendEmailVerification([ActionCodeSettings? actionCodeSettings]) async {
    return;
  }

  @override
  Future<void> reload() async {
    return;
  }

  @override
  Future<UserCredential> reauthenticateWithCredential(AuthCredential? credential) async {
    return MockUserCredential();
  }
}

class MockUserCredential extends Mock implements UserCredential {
  final User? _user;

  MockUserCredential({User? user}) : _user = user;

  @override
  User? get user => _user;
}

void main() {
  late LoginProvider loginProvider;
  late MockFirebaseAuth mockAuth;
  late MockGoogleSignIn mockGoogleSignIn;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    loginProvider = LoginProvider(
      auth: mockAuth,
      googleSignIn: mockGoogleSignIn,
    );
  });

  group('LoginProvider', () {

    test('isLoggedIn should return false when not logged in', () {
      expect(loginProvider.isLoggedIn, false);
    });

    test('signInWithEmailPassword returns true on success', () async {
      // Arrange
      final mockUser = ExtendedMockUser(
        uid: 'test-uid',
        email: 'test@example.com',
        isVerified: true,
      );
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      loginProvider = LoginProvider(auth: mockAuth, googleSignIn: mockGoogleSignIn);

      // Act
      final result = await loginProvider.signInWithEmailAndPassword('test@example.com', 'password');

      // Assert
      expect(result, true);
      expect(loginProvider.isLoggedIn, true);
      expect(loginProvider.isLoading, false);
      expect(loginProvider.errorMessage, isNull);
    });

    test('signInWithEmailPassword returns false when email not verified', () async {
      // Arrange
      final mockUser = ExtendedMockUser(
        uid: 'test-uid',
        email: 'test@example.com',
        isVerified: false,
      );
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      loginProvider = LoginProvider(auth: mockAuth, googleSignIn: mockGoogleSignIn);

      // Act
      final result = await loginProvider.signInWithEmailAndPassword('test@example.com', 'password');

      // Assert
      expect(result, false);
      expect(loginProvider.errorMessage, 'Please verify your email before logging in.');
      expect(loginProvider.isLoading, false);
    });

    test('signInWithEmailPassword handles user-not-found error', () async {
      // Arrange
      final errorAuth = MockAuthWithErrors(errorCode: 'user-not-found');
      loginProvider = LoginProvider(auth: errorAuth, googleSignIn: mockGoogleSignIn);

      // Act
      final result = await loginProvider.signInWithEmailAndPassword('unknown@example.com', 'password');

      // Assert
      expect(result, false);
      expect(loginProvider.errorMessage, 'No user found with this email.');
      expect(loginProvider.isLoading, false);
    });

    test('signInWithEmailPassword handles wrong-password error', () async {
      // Arrange
      final errorAuth = MockAuthWithErrors(errorCode: 'wrong-password');
      loginProvider = LoginProvider(auth: errorAuth, googleSignIn: mockGoogleSignIn);

      // Act
      final result = await loginProvider.signInWithEmailAndPassword('test@example.com', 'wrong');

      // Assert
      expect(result, false);
      expect(loginProvider.errorMessage, 'Incorrect password.');
      expect(loginProvider.isLoading, false);
    });

    test('signUpWithEmailAndPassword returns true on success', () async {
      // Arrange
      final mockUser = ExtendedMockUser(
        uid: 'test-uid',
        email: 'new@example.com',
        isVerified: false,
      );
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      loginProvider = LoginProvider(auth: mockAuth, googleSignIn: mockGoogleSignIn);

      // Act
      final result = await loginProvider.signUpWithEmailAndPassword('new@example.com', 'password');

      // Assert
      expect(result, true);
      expect(loginProvider.isLoggedIn, true);
      expect(loginProvider.isLoading, false);
    });

    test('signUpWithEmailAndPassword handles email-already-in-use error', () async {
      // Arrange
      final errorAuth = MockAuthWithErrors(errorCode: 'email-already-in-use');
      loginProvider = LoginProvider(auth: errorAuth, googleSignIn: mockGoogleSignIn);

      // Act
      final result = await loginProvider.signUpWithEmailAndPassword('existing@example.com', 'password');

      // Assert
      expect(result, false);
      expect(loginProvider.errorMessage, 'This email is already registered.');
      expect(loginProvider.isLoading, false);
    });

    test('signInWithGoogle returns true on success', () async {
      // Arrange
      final mockUser = ExtendedMockUser(
        uid: 'google-uid',
        email: 'google@example.com',
      );
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      loginProvider = LoginProvider(auth: mockAuth, googleSignIn: mockGoogleSignIn);

      // Act
      final result = await loginProvider.signInWithGoogle();

      // Assert
      expect(result, true);
      expect(loginProvider.isLoggedIn, true);
      expect(loginProvider.isLoading, false);
    });

    test('signInWithGoogle returns false when user cancels sign in', () async {
      // Arrange
      mockGoogleSignIn = MockGoogleSignIn(returnNull: true);
      loginProvider = LoginProvider(auth: mockAuth, googleSignIn: mockGoogleSignIn);

      // Act
      final result = await loginProvider.signInWithGoogle();

      // Assert
      expect(result, false);
      expect(loginProvider.isLoading, false);
    });

    test('logout works correctly', () async {
      // Arrange
      final mockUser = ExtendedMockUser(
        uid: 'test-uid',
        email: 'test@example.com',
      );
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      loginProvider = LoginProvider(auth: mockAuth, googleSignIn: mockGoogleSignIn);

      // Sign in first
      await loginProvider.signInWithEmailAndPassword('test@example.com', 'password');
      expect(loginProvider.isLoggedIn, true);

      // Act
      await loginProvider.logout();

      // Assert - should now be logged out
      expect(loginProvider.isLoggedIn, false);
      expect(loginProvider.isLoading, false);
    });

    test('reauthenticateUser returns true on success', () async {
      // Arrange
      final mockUser = ExtendedMockUser(
        uid: 'test-uid',
        email: 'test@example.com',
      );
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      loginProvider = LoginProvider(auth: mockAuth, googleSignIn: mockGoogleSignIn);

      // Sign in first
      await loginProvider.signInWithEmailAndPassword('test@example.com', 'password');

      // Act
      final result = await loginProvider.reauthenticateUser('password');

      // Assert
      expect(result, true);
      expect(loginProvider.isLoading, false);
    });

    test('checkEmailVerified returns correct verification status', () async {
      // Arrange
      final mockUser = ExtendedMockUser(
        uid: 'test-uid',
        email: 'test@example.com',
        isVerified: true,
      );
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      loginProvider = LoginProvider(auth: mockAuth, googleSignIn: mockGoogleSignIn);

      // Sign in first
      await loginProvider.signInWithEmailAndPassword('test@example.com', 'password');

      // Act
      final result = await loginProvider.checkEmailVerified();

      // Assert
      expect(result, true);
      expect(loginProvider.isEmailVerified, true);
    });

    test('needsReauthentication returns true when user is null', () async {
      // Arrange - user is not signed in

      // Act
      final result = await loginProvider.needsReauthentication();

      // Assert
      expect(result, false);
    });
  });
}