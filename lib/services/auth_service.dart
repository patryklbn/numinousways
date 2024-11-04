import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Sign in with email and password
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
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
      return userCredential.user;
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
