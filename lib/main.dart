import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/login/register_screen.dart';
import 'screens/login/forgotpassword_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'viewmodels/profile_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

// Firebase initialization function
Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    }
  }
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
      home: const LoginScreen(), // Start with LoginScreen
      onGenerateRoute: (settings) {
        if (settings.name == '/profile_screen') {
          // Expect arguments as a map with both 'userId' and 'loggedInUserId'
          final arguments = settings.arguments as Map<String, String>;
          final userId = arguments['userId']!;
          final loggedInUserId = arguments['loggedInUserId']!;

          // Pass both arguments to ProfileScreen
          return MaterialPageRoute(
            builder: (context) => ProfileScreen(
              userId: userId,
              loggedInUserId: loggedInUserId,
            ),
          );
        }
        // Define other routes similarly
        switch (settings.name) {
          case '/onboarding':
            return MaterialPageRoute(builder: (context) => OnboardingScreen());
          case '/login':
            return MaterialPageRoute(builder: (context) => LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (context) => RegisterScreen());
          case '/forgot-password':
            return MaterialPageRoute(builder: (context) => ForgotPasswordScreen());
          default:
            return null;
        }
      },
    );
  }
}
