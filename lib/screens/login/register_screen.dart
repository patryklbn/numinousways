import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/dialog_helper.dart';
import '../../utils/validators.dart';
import 'package:provider/provider.dart';
import '../../services/login_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Register function that sends email verification
  Future<void> _register() async {


    // Validate form
    if (!_formKey.currentState!.validate()) {
      print('>>> Form validation failed. Aborting registration.');
      return;
    }

    setState(() {
      _isLoading = true;
    });
    print('>>> Form is valid. _isLoading set to true.');

    final loginProvider = Provider.of<LoginProvider>(context, listen: false);

    try {
      print('>>> Starting signUpWithEmailAndPassword...');
      bool registrationSuccess = await loginProvider.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      print('>>> signUpWithEmailAndPassword returned: $registrationSuccess');

      // If registration failed, show error message
      if (!registrationSuccess) {
        setState(() {
          _isLoading = false;
        });
        print('>>> registrationSuccess == false, so returning early.');
        if (loginProvider.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loginProvider.errorMessage!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Registration succeeded, get the user ID
      final userId = loginProvider.userId;
      print('>>> userId from loginProvider: $userId');
      if (userId == null) {
        throw Exception("Registration succeeded but no user ID was provided.");
      }

      // Save the user's info in Firestore with proper error handling
      bool firestoreSuccess = false;
      try {
        print('>>> Attempting to create Firestore doc in "users/$userId"');

        // Get current user to check email verification status
        final User? currentUser = FirebaseAuth.instance.currentUser;

        // Add timeout to prevent hanging
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'id': userId,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'emailVerified': currentUser?.emailVerified ?? false,
          'bio': '',
          'location': '',
          'gender': null,
          'age': null,
          'profileImageUrl': null,
        }).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            print('>>> Firestore operation timed out after 15 seconds');
            throw TimeoutException('Firestore operation timed out');
          },
        );

        print('>>> Firestore doc created successfully for userId: $userId');
        firestoreSuccess = true;
      } catch (e) {
        print('>>> Failed to create user doc: $e');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print('>>> _isLoading set to false. Showing success dialog...');

        // Show a success dialog with verification instructions
        String message = "Welcome ${_nameController.text}!\n\n";
        if (firestoreSuccess) {
          message += "Registration successful! Please check your email to verify your account before logging in.";
        } else {
          message += "Your account was created, but there was an issue saving your profile data. "
              "Please check your email to verify your account before logging in. "
              "You can update your profile information after logging in.";
        }

        await DialogHelper.showSuccessDialog(context, message);
        print('>>> Success dialog closed. Now logging out user...');

        // Sign out the user - they need to verify email before logging in
        await loginProvider.logout();

        // Navigate back to login screen
        if (mounted) {
          print('>>> Navigating back to the previous screen...');
          Navigator.pop(context);
        }
      }
    } catch (e, stackTrace) {
      print('>>> Error during registration: $e');
      print(stackTrace);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF333333)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF333333),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: _buildRegistrationForm(),
    );
  }

  // Registration form widget
  Widget _buildRegistrationForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const SizedBox(height: 20.0),

            // Title Text
            const Text(
              "Create Account",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 24.0),

            // Name TextField
            TextFormField(
              controller: _nameController,
              validator: Validators.validateName,
              decoration: InputDecoration(
                labelText: "Name",
                hintText: "Enter your display name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Email TextField
            TextFormField(
              controller: _emailController,
              validator: Validators.validateEmail,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Password TextField
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              validator: Validators.validatePassword,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Confirm Password TextField
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              validator: (value) => Validators.confirmPassword(
                _passwordController.text.trim(),
                _confirmPasswordController.text.trim(),
              ),
              decoration: InputDecoration(
                labelText: "Confirm Password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 24.0),

            // Register Button
            SizedBox(
              width: double.infinity,
              height: 50.0,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF37474F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.0,
                  ),
                )
                    : const Text("Register"),
              ),
            ),
            const SizedBox(height: 16.0),

            // Back to Login
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Already have an account? Login",
                  style: TextStyle(
                    color: Color(0xFF37474F),
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40.0),
          ],
        ),
      ),
    );
  }
}