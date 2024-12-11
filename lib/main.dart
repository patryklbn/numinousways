import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/login/register_screen.dart';
import 'screens/login/forgotpassword_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/timeline/timeline_screen.dart';
import 'screens/my_retreat/my_retreat_screen.dart';
import 'screens/my_retreat/retreat_info_screen.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'services/login_provider.dart';
import 'widgets/app_drawer.dart';
import 'screens/main_app_with_drawer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
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
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ProfileViewModel()),
          ChangeNotifierProvider(create: (_) => LoginProvider()),
        ],
        child: MaterialApp(
          title: 'Your App Name',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Color(0xFFEFF3F7),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.blue,
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 24),
              iconTheme: IconThemeData(color: Colors.white),
            ),
          ),
          home: Consumer<LoginProvider>(
            builder: (context, loginProvider, child) {
              if (loginProvider.isLoggedIn) {
                print(
                    "Navigating to TimelineScreen with userId: ${loginProvider
                        .userId}");
                return TimelineScreen(); // Do not pass userId
              } else {
                print("Navigating to LoginScreen");
                return LoginScreen();
              }
            },
          ),
          onGenerateRoute: (settings) {
            if (settings.name == '/profile_screen') {
              final args = settings.arguments as Map<String, String>;
              return MaterialPageRoute(
                builder: (context) =>
                    ProfileScreen(
                      userId: args['userId']!,
                      loggedInUserId: args['loggedInUserId']!,
                    ),
              );
            }
            return null; // Default return for undefined routes
          },
          routes: {
            '/onboarding': (context) => OnboardingScreen(),
            '/register': (context) => RegisterScreen(),
            '/forgot-password': (context) => ForgotPasswordScreen(),
            '/timeline': (context) => TimelineScreen(),
            '/edit_profile': (context) => EditProfileScreen(),
            '/my_retreat': (context) => MyRetreatScreen(),
            '/retreat_info': (context) => RetreatInfoScreen(),
          },
        )
    );
  }
}
