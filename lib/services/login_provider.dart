import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userId;

  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;

  LoginProvider() {
    // Listen to authentication state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        _isLoggedIn = false;
        _userId = null;
        notifyListeners();
      } else {
        _isLoggedIn = true;
        _userId = user.uid;
        notifyListeners();
      }
    });
  }

  Future<void> login(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // The authStateChanges listener will handle updating the state
      print("Logged in");
    } catch (e) {
      print("Login error: $e");
    }
  }

  void logout() {
    FirebaseAuth.instance.signOut();
    // The authStateChanges listener will handle updating the state
  }
}
