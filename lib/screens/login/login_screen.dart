import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../utils/dialog_helper.dart';
import '../../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // Email and password sign-in with navigation
  Future<void> _signInWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Attempt sign in
      final user = await _authService.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user == null) {
        // Could not sign in (wrong creds, no user, etc.)
        if (mounted) {
          setState(() => _isLoading = false);
          DialogHelper.showErrorDialog(context, "User not found.");
        }
        return;
      }

      // Force a reload to get the latest verification status
      await user.reload();
      final refreshedUser = _auth.currentUser;

      // Debug: Output verification status
      print("Email verification status: ${refreshedUser?.emailVerified}");

      if (refreshedUser != null && refreshedUser.emailVerified) {
        // Email is verified, proceed to the main app
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.pushReplacementNamed(
            context,
            '/timeline',
            arguments: {
              'userId': refreshedUser.uid,
              'loggedInUserId': refreshedUser.uid,
            },
          );
        }
      } else {
        // Email not verified - ENFORCE verification requirement
        if (mounted) {
          setState(() => _isLoading = false);
          // Show verification dialog
          _showVerificationDialog(refreshedUser ?? user);
        }
      }
    } catch (e) {
      // Handle errors
      if (mounted) {
        setState(() => _isLoading = false);
        DialogHelper.showErrorDialog(context, e.toString());
      }
    }
  }

  // Google Sign-In with navigation
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      // Attempt Google sign-in
      final user = await _authService.signInWithGoogle();

      if (user == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          DialogHelper.showErrorDialog(context, "Google sign-in failed.");
        }
        return;
      }

      // Google accounts are typically already verified
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(
          context,
          '/timeline',
          arguments: {
            'userId': user.uid,
            'loggedInUserId': user.uid,
          },
        );
      }
    } catch (e) {
      // Handle errors
      if (mounted) {
        setState(() => _isLoading = false);
        DialogHelper.showErrorDialog(context, e.toString());
      }
    }
  }

  // Show verification dialog when email is not verified
  void _showVerificationDialog(User user) {
    showDialog(
      context: context,
      barrierDismissible: false, // force the user to pick an action
      builder: (context) {
        return AlertDialog(
          title: const Text('Email Verification Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your email address has not been verified. '
                    'Please check your inbox for a verification email and follow the instructions.',
              ),
              const SizedBox(height: 8),
              const Text(
                'If you can\'t find the email, check your spam folder or request a new verification email.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              const Text(
                'Note: After clicking the verification link, you might see a message about the link being expired or already used. This is normal - your email will still be verified, and you can return to this app to log in.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              Text(
                'Email: ${user.email}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            // Cancel / Close
            TextButton(
              onPressed: () {
                // Sign out the user since they're not verified
                _auth.signOut();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            // Resend verification
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _sendVerificationEmail();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Resend Verification Email'),

            ),
          ],
        );
      },
    );
  }

  // Send verification email to the current user
  Future<void> _sendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Make sure we have the most up-to-date user
        await user.reload();

        // Send verification email
        await user.sendEmailVerification();
        print("Verification email sent to: ${user.email}");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New verification email sent! Please check your inbox and spam folder.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );

          // Show a dialog explaining what to do next
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Verification Email Sent'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('A verification email has been sent to ${user.email}.'),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Check your inbox and spam folder',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    '2. Click the verification link in the email',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    '3. After verification, return to this app and log in',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Note: You may see a message about the link being expired or already used after clicking it. This is normal - your email will still be verified.',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No user is currently signed in.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("Error sending verification email: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending verification email: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ------- TOP SECTION -------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const SizedBox(height: 80.0),
                    const Text(
                      "Hello Again",
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
                        labelStyle: const TextStyle(color: Color(0xFF333333)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Password TextField
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: Validators.validatePassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: const TextStyle(color: Color(0xFF333333)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: const Color(0xFF333333),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 8.0),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/forgot-password');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF37474F),
                        ),
                        child: const Text("Forgot password?"),
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // -------- LOGIN BUTTON --------
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signInWithEmailAndPassword,
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
                            : const Text("Login"),
                      ),
                    ),

                    const SizedBox(height: 24.0),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            color: Colors.grey[400],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text("or login with"),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24.0),

                    // -------- GOOGLE LOGIN BUTTON (ICON) --------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.email),
                          iconSize: 32.0,
                          color: const Color(0xFF37474F),
                          onPressed: _isLoading ? null : _signInWithGoogle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24.0),
                  ],
                ),
              ),
            ),
          ),

          // ------- BOTTOM SECTION -------
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text.rich(
                  TextSpan(
                    text: "Don't have an account? ",
                    style: TextStyle(color: Color(0xFF333333)),
                    children: [
                      TextSpan(
                        text: "Register Now",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF37474F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}