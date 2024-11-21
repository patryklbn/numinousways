import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userId;

  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;

  Future<void> login(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set the user ID to the currently logged-in user's ID
      _userId = userCredential.user?.uid;
      _isLoggedIn = true;
      notifyListeners();
      print("Logged in with userId: $_userId");  // Debug message

    } catch (e) {
      // Handle login errors (e.g., show error messages)
      print("Login error: $e");
    }
  }

  void logout() {
    _isLoggedIn = false;
    _userId = null; // Clear the user ID on logout
    FirebaseAuth.instance.signOut();
    notifyListeners();
  }
}
