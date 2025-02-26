import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/dialog_helper.dart';
import '../../utils/validators.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Register function that shows a success dialog instead of switching to success UI
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user account
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save the user's name and other profile info to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show a success dialog upon registration
        await DialogHelper.showSuccessDialog(
          context,
          "Welcome ${_nameController.text}!\n\nRegistration successful! Your account has been created.",
        );

        // Navigate to onboarding after the user dismisses the dialog
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/timeline');
        }
      }
    } catch (e) {
      // Handle errors
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show error directly in a SnackBar instead of a dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Navigate to onboarding (called after dialog is dismissed, in this example)
  void _continueToOnboarding() {
    Navigator.pushReplacementNamed(context, '/onboarding');
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
