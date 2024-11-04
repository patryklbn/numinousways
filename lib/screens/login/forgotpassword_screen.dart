import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../../utils/dialog_helper.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Function to handle password reset
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _authService.resetPassword(_emailController.text.trim());
      DialogHelper.showSuccessDialog(context, 'A password reset link has been sent to your email.');
    } catch (e) {
      DialogHelper.showErrorDialog(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Forgot Password"),
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
            shrinkWrap: true,
            children: [
              const SizedBox(height: 20.0), // Reduced top padding

              // Illustration image
              Image.asset(
                'assets/images/forgott-password.png',
                height: 250,
                width: 250,
              ),
              const SizedBox(height: 24.0),

              // Title Text
              Text(
                "Reset Your Password",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24.0),

              // Email TextField with validation
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
              const SizedBox(height: 24.0),

              // Send Reset Link Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _resetPassword,
                  child: Text("Send Reset Link"),
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
            ],
          ),
        ),
      ),
    );
  }
}
