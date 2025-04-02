import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthService({FirebaseAuth? authInstance, GoogleSignIn? googleSignIn})
      : _auth = authInstance ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  // Sign in with email and password
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user
      User? user = userCredential.user;

      // Force reload to get latest verification status
      if (user != null) {
        await user.reload();
        // Get refreshed user
        user = _auth.currentUser;

        print("User logged in: ${user?.email}, Verified: ${user?.emailVerified}");
      }

      return user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw 'No account found for this email. Please check and try again.';
        case 'wrong-password':
          throw 'Incorrect password. Please try again.';
        case 'invalid-email':
          throw 'Invalid email format. Please enter a valid email.';
        case 'user-disabled':
          throw 'This user account has been disabled. Please contact support.';
        default:
          throw 'An unknown error occurred. Please try again later. [Error: ${e.code}]';
      }
    } catch (e) {
      throw 'An error occurred. Please try again later. Details: ${e.toString()}';
    }
  }

  // Send verification email
  Future<void> sendVerificationEmail() async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw 'No user is currently signed in.';
    }

    try {
      await user.reload();
      user = _auth.currentUser;

      if (user != null) {
        await user.sendEmailVerification();
        print("Verification email sent to: ${user.email}");
      }
    } catch (e) {
      print("Error sending verification email: $e");
      throw 'Error sending verification email: ${e.toString()}';
    }
  }

  // Handle expired verification link
  Future<void> handleExpiredVerificationLink(BuildContext context) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in again to request a new verification email.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await user.reload();
      user = _auth.currentUser;

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A new verification email has been sent. Please check your inbox.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      } else if (user != null && user.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your email is already verified! You can continue using the app.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Check if email is verified (with reload)
  Future<bool> isEmailVerified() async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    try {
      await user.reload();
      user = _auth.currentUser;
      return user?.emailVerified ?? false;
    } catch (e) {
      print("Error checking email verification: $e");
      return false;
    }
  }

  // Password reset with error handling
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw 'No account found for this email. Please check and try again.';
        case 'invalid-email':
          throw 'Invalid email format. Please enter a valid email.';
        default:
          throw 'An unknown error occurred. Please try again later. [Error: ${e.code}]';
      }
    } catch (e) {
      throw 'An error occurred. Please try again later. Details: ${e.toString()}';
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw 'Sign-in aborted by user';
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      User? user = userCredential.user;
      print("Google sign-in: ${user?.email}");

      return user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw 'The account already exists with a different sign-in method.';
        case 'invalid-credential':
          throw 'The Google credentials are invalid or have expired.';
        default:
          throw 'An unknown error occurred. Please try again later. [Error: ${e.code}]';
      }
    } catch (e) {
      throw 'An error occurred. Please try again later. Details: ${e.toString()}';
    }
  }
}
