import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:numinous_way/screens/login/forgotpassword_screen.dart';
import 'firebase_options.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/login/register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      // Firebase app is already initialized, proceed normally
    } else {
      // Handle other errors
      rethrow;
    }
  }

  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App Name',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(), // Start with LoginScreen for initial testing
      routes: {
        '/onboarding': (context) => OnboardingScreen(), // Onboarding route
        '/login': (context) => LoginScreen(), // Login route
        '/register': (context) => RegisterScreen(), // Register route
        '/forgot-password': (context) => ForgotPasswordScreen(), // Forgot Password route
      },
    );
  }
}
