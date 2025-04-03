import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginProvider extends ChangeNotifier {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  String? get userId => _user?.uid;
  bool get isEmailVerified => _user?.emailVerified ?? false;

  // Constructor with dependency injection
  LoginProvider({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn
  }) :
        _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }


  /// Creates or updates a user document in Firestore
  Future<bool> _ensureUserDocument(User user) async {
    try {
      final userId = user.uid;
      print('Ensuring Firestore document for user: $userId');

      // Check if document already exists
      final docSnapshot = await _firestore.collection('users').doc(userId).get()
          .timeout(const Duration(seconds: 10));

      if (!docSnapshot.exists) {
        print('Creating new user document for: $userId');

        // Create user data map
        Map<String, dynamic> userData = {
          'id': userId,
          'name': user.displayName ?? 'User',
          'email': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'emailVerified': user.emailVerified,
          'bio': '',
          'location': '',
          'gender': null,
          'age': null,
          'profileImageUrl': user.photoURL,
        };

        // Set document with retry mechanism
        bool success = false;
        for (int i = 0; i < 3; i++) {
          try {
            await _firestore.collection('users').doc(userId).set(userData)
                .timeout(const Duration(seconds: 10));
            success = true;
            break;
          } catch (e) {
            print('Attempt ${i+1} failed: $e');
            if (i < 2) await Future.delayed(const Duration(seconds: 1));
          }
        }

        if (!success) {
          print('All attempts to create user document failed');
          return false;
        }

        // Verify document was created
        final verifyDoc = await _firestore.collection('users').doc(userId).get()
            .timeout(const Duration(seconds: 5));

        if (verifyDoc.exists) {
          print('User document created and verified: $userId');
          return true;
        } else {
          print('Document creation verification failed');
          return false;
        }
      } else {
        print('User document already exists: $userId');

        // Ensure essential fields are present (for backward compatibility)
        final data = docSnapshot.data();
        bool needsUpdate = false;
        Map<String, dynamic> updates = {};

        if (data != null) {
          if (data['email'] == null || data['email'] == '') {
            updates['email'] = user.email ?? '';
            needsUpdate = true;
          }

          if (data['emailVerified'] != user.emailVerified) {
            updates['emailVerified'] = user.emailVerified;
            needsUpdate = true;
          }
        }

        if (needsUpdate) {
          await _firestore.collection('users').doc(userId).update(updates)
              .timeout(const Duration(seconds: 5));
          print('Updated existing user document with new data');
        }

        return true;
      }
    } catch (e) {
      print('Error ensuring user document: $e');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}, message: ${e.message}');
      }
      return false;
    }
  }


  /// Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    _setLoading(true);

    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );
      _user = result.user;

      // Check if email is verified
      if (_user != null && !_user!.emailVerified) {
        _setError('Please verify your email before logging in.');
        return false;
      }

      // Ensure Firestore document
      if (_user != null) {
        await _ensureUserDocument(_user!);
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Sign up with email and password
  Future<bool> signUpWithEmailAndPassword(String email, String password) async {
    _setLoading(true);

    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );
      _user = result.user;

      // Create user document
      if (_user != null) {
        await _ensureUserDocument(_user!);
        // Send email verification
        await sendEmailVerification();
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Sign in with Google - Fixed implementation
  Future<bool> signInWithGoogle() async {
    _setLoading(true);

    try {
      print('Starting Google sign-in process');

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('User canceled Google sign-in');
        _setLoading(false);
        return false;
      }

      print('Google account selected: ${googleUser.email}');

      // auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential result = await _auth.signInWithCredential(credential);
      _user = result.user;

      // Create Firestore document if authentication successful
      if (_user != null) {
        print('Google auth successful for: ${_user!.uid}');

        // Ensure document exists with retries
        bool docCreated = false;
        for (int attempt = 0; attempt < 3; attempt++) {
          try {
            print('Creating Firestore document, attempt ${attempt + 1}');
            docCreated = await _ensureUserDocument(_user!);
            if (docCreated) {
              print('Document created successfully');
              break;
            }
            await Future.delayed(const Duration(seconds: 1));
          } catch (e) {
            print('Error in document creation attempt ${attempt + 1}: $e');
            await Future.delayed(const Duration(seconds: 1));
          }
        }

        if (!docCreated) {
          print('WARNING: Failed to create user document after multiple attempts');
        }
      }

      _setLoading(false);
      return true;
    } catch (e) {
      print('Error during Google sign-in: $e');
      _setError(e.toString());
      return false;
    }
  }

  /// Send email verification
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
      print("Error sending verification email: $e");
      _setError('Error sending verification email: $e');
      return false;
    }
  }

  /// Check if email is verified (refreshes user)
  Future<bool> checkEmailVerified() async {
    if (_user == null) return false;

    try {
      // Reload user to get the latest email verification status
      await _user!.reload();
      _user = _auth.currentUser;

      // If email is verified, update Firestore
      if (_user?.emailVerified ?? false) {
        await _updateEmailVerificationStatus();
      }

      notifyListeners();
      return _user?.emailVerified ?? false;
    } catch (e) {
      _setError('Error checking email verification: $e');
      return false;
    }
  }

  /// Update email verification status in Firestore
  Future<void> _updateEmailVerificationStatus() async {
    try {
      if (_user != null && _user!.emailVerified) {
        await _firestore.collection('users').doc(_user!.uid).update({
          'emailVerified': true
        }).timeout(const Duration(seconds: 10));

        print('Firestore emailVerified flag updated successfully');
      }
    } catch (e) {
      print('Error updating email verification status: $e');
      // Non-critical operation, so we don't set user-facing error
    }
  }

  /// Sign out
  Future<void> logout() async {
    _setLoading(true);

    try {
      // Sign out from Firebase
      await _auth.signOut();

      // Sign out from Google if it was used
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      _user = null;
      _setLoading(false);
    } catch (e) {
      _setError('Error signing out: $e');
      throw e; // Rethrow for the caller to handle
    }
  }

  /// Validate current user and ensure Firestore document
  Future<bool> validateCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        print('User validation: No current user found');
        return false;
      }

      // Try to reload the user to verify they still exist in Firebase
      try {
        await currentUser.reload();

        // Check that reload worked and user still exists
        final refreshedUser = _auth.currentUser;
        if (refreshedUser == null) {
          print('User validation: User no longer exists after reload');
          return false;
        }

        // Ensure Firestore document exists
        await _ensureUserDocument(refreshedUser);

      } catch (e) {
        print('User validation: Error reloading user - $e');
        // If we get an error during reload, the user likely doesn't exist
        return false;
      }

      return true;
    } catch (e) {
      print('User validation: Error validating user - $e');
      return false;
    }
  }

  /// Reauthenticate user (for sensitive operations)
  Future<bool> reauthenticateUser(String password) async {
    _setLoading(true);

    try {
      if (_user == null || _user!.email == null) {
        _setError('No authenticated user found');
        return false;
      }

      // Create credential
      AuthCredential credential = EmailAuthProvider.credential(
          email: _user!.email!,
          password: password
      );

      // Reauthenticate
      await _user!.reauthenticateWithCredential(credential);

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Check if current user needs reauthentication for sensitive operations
  Future<bool> needsReauthentication() async {
    if (_user == null) return false;

    // Get user metadata
    final metadata = _user!.metadata;
    final lastSignInTime = metadata.lastSignInTime;

    // If last sign-in was more than 30 minutes ago, require reauthentication
    if (lastSignInTime != null) {
      final diff = DateTime.now().difference(lastSignInTime);
      return diff.inMinutes > 30;
    }

    return true;
  }


  /// Set loading state and notify listeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    _errorMessage = null;
    notifyListeners();
  }

  /// Set error message and notify listeners
  void _setError(String message) {
    _isLoading = false;
    _errorMessage = message;
    notifyListeners();
  }

  /// Handle Firebase authentication errors
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

  // Legacy method for compatibility
  Future<void> login(String email, String password) async {
    await signInWithEmailAndPassword(email, password);
  }
}