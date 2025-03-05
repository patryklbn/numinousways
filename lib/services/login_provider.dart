import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  String? get userId => _user?.uid;
  bool get isEmailVerified => _user?.emailVerified ?? false;

  // Initialize user state
  LoginProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );
      _user = result.user;

      // Check if email is verified
      if (_user != null && !_user!.emailVerified) {
        _errorMessage = 'Please verify your email before logging in.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Sign up with email and password
  Future<bool> signUpWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );
      _user = result.user;

      // Send email verification
      await sendEmailVerification();

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Send email verification
  Future<bool> sendEmailVerification() async {
    if (_user == null) {
      print("Error: Cannot send verification email - user is null");
      return false;
    }

    try {
      await _user!.sendEmailVerification();
      print("Verification email sent successfully");
      return true;
    } catch (e) {
      print("Error sending verification email: ${e.toString()}");
      _errorMessage = 'Error sending verification email: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Check if email is verified (refreshes user)
  Future<bool> checkEmailVerified() async {
    if (_user == null) return false;

    try {
      // Reload user to get the latest email verification status
      await _user!.reload();
      _user = _auth.currentUser;
      notifyListeners();
      return _user?.emailVerified ?? false;
    } catch (e) {
      _errorMessage = 'Error checking email verification: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the Google Sign In flow
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential result = await _auth.signInWithCredential(credential);
      _user = result.user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Handle auth errors
  void _handleAuthError(FirebaseAuthException e) {
    _isLoading = false;
    switch (e.code) {
      case 'user-not-found':
        _errorMessage = 'No user found with this email.';
        break;
      case 'wrong-password':
        _errorMessage = 'Incorrect password.';
        break;
      case 'email-already-in-use':
        _errorMessage = 'This email is already registered.';
        break;
      case 'weak-password':
        _errorMessage = 'The password is too weak.';
        break;
      case 'invalid-email':
        _errorMessage = 'Invalid email address.';
        break;
      case 'operation-not-allowed':
        _errorMessage = 'This sign-in method is not enabled.';
        break;
      case 'requires-recent-login':
        _errorMessage = 'This operation requires recent authentication. Please re-login and try again.';
        break;
      default:
        _errorMessage = 'Authentication error: ${e.message}';
        break;
    }
    notifyListeners();
  }

  // Login method (compatible with your original code)
  Future<void> login(String email, String password) async {
    await signInWithEmailAndPassword(email, password);
  }

  // Sign out method
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Sign out from Firebase
      await _auth.signOut();

      // Sign out from Google if it was used
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Local data would be cleared here if you had SharedPreferences
      // Consider adding shared_preferences package if you need to store local data

      _user = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error signing out: ${e.toString()}';
      notifyListeners();
      throw e; // Rethrow for the caller to handle
    }
  }

  // Method to re-authenticate user (needed for sensitive operations like account deletion)
  Future<bool> reauthenticateUser(String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_user == null || _user!.email == null) {
        _errorMessage = 'No authenticated user found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Create credential
      AuthCredential credential = EmailAuthProvider.credential(
          email: _user!.email!,
          password: password
      );

      // Reauthenticate
      await _user!.reauthenticateWithCredential(credential);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Check if current user needs reauthentication
  Future<bool> needsReauthentication() async {
    if (_user == null) return false;

    // Get user metadata
    final metadata = _user!.metadata;
    final lastSignInTime = metadata.lastSignInTime;

    // If last sign-in was more than 30 minutes ago, require reauthentication for sensitive operations
    if (lastSignInTime != null) {
      final diff = DateTime.now().difference(lastSignInTime);
      return diff.inMinutes > 30;
    }

    return true; // Default to requiring reauthentication if we can't determine
  }
}