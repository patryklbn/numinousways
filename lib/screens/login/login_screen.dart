import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;

  // Define the primary and accent colors
  final Color primaryColor = Color(0xFFB0BEC5); // Light Gray
  final Color accentColor = Color(0xFF37474F);  // Dark Gray

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ListView(
                children: [
                  const SizedBox(height: 80.0), // Space at the top

                  // Greeting Text
                  Text(
                    "Hello Again",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333), // Dark gray color
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Email TextField
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Email",
                      labelStyle: TextStyle(color: Color(0xFF333333)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Password TextField
                  TextField(
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: TextStyle(color: Color(0xFF333333)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primaryColor),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Color(0xFF333333),
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

                  // Forgot Password Text
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Add forgot password functionality here
                      },
                      child: Text("Forgot password?"),
                      style: TextButton.styleFrom(
                        foregroundColor: accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Add login functionality here
                      },
                      child: Text("Login"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Divider with "or login with" text
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 1,
                          color: Colors.grey[400],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
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

                  // Social Media Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.facebook),
                        iconSize: 32.0,
                        color: accentColor,
                        onPressed: () {
                          // Add Facebook login functionality
                        },
                      ),
                      const SizedBox(width: 16.0),
                      IconButton(
                        icon: Icon(Icons.email),
                        iconSize: 32.0,
                        color: accentColor,
                        onPressed: () {
                          // Add Gmail login functionality
                        },
                      ),
                      const SizedBox(width: 16.0),
                      IconButton(
                        icon: Icon(Icons.apple),
                        iconSize: 32.0,
                        color: accentColor,
                        onPressed: () {
                          // Add Apple login functionality
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Register Now Text
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  // Navigate to register page
                },
                child: Text.rich(
                  TextSpan(
                    text: "Don’t have an account? ",
                    style: TextStyle(color: Color(0xFF333333)),
                    children: [
                      TextSpan(
                        text: "Register Now",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: accentColor,
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
