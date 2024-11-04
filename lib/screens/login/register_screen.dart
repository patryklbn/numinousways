import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/dialog_helper.dart';
import '../../utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Register function with success dialog
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Show success dialog after successful registration
      await DialogHelper.showSuccessDialog(
        context,
        'Registration successful! Welcome to our app.',
      );

      // Navigate to the onboarding screen
      Navigator.pushReplacementNamed(context, '/onboarding');
    } catch (e) {
      DialogHelper.showErrorDialog(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Register"),
        backgroundColor: Color(0xFFF5F5F5),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF333333)),
        titleTextStyle: TextStyle(
          color: Color(0xFF333333),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 20.0),

              // Title Text
              Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 24.0),

              // Email TextField
              TextFormField(
                controller: _emailController,
                validator: Validators.validateEmail,
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
                child: ElevatedButton(
                  onPressed: _register,
                  child: Text("Register"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF37474F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),

              // Back to Login
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Text(
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
      ),
    );
  }
}
