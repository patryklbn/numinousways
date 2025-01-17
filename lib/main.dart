import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

// Firebase config
import 'firebase_options.dart';

// Screens
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/login/register_screen.dart';
import 'screens/login/forgotpassword_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/timeline/timeline_screen.dart';
import 'screens/my_retreat/my_retreat_screen.dart';
import 'screens/my_retreat/retreat_info_screen.dart';
import 'screens/my_retreat/preparation/preparation_course_screen.dart';
import 'screens/my_retreat/preparation/day_detail_screen.dart';
import 'screens/main_app_with_drawer.dart';

// ViewModels / Providers
import 'viewmodels/profile_viewmodel.dart';
import 'services/login_provider.dart';
import 'services/myretreat_service.dart';
import 'services/firestore_service.dart';
import 'services/storage_service.dart';

// The Preparation-related imports
import 'services/preparation_course_service.dart';
import 'viewmodels/preparation_provider.dart';

// The new day detail provider
import 'viewmodels/day_detail_provider.dart';

import 'package:numinous_way/services/notification_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();

  final notificationService = NotificationService();
  await notificationService.init(); // Initialize notifications here!

  // Request permissions for notifications on iOS
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<NotificationService>.value(value: notificationService), // Register notification service
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        Provider(
          create: (_) => MyRetreatService(
            firestoreService: FirestoreService(),
            storageService: StorageService(),
          ),
        ),
        // We'll create the PreparationProvider only after the user logs in (see below).
      ],
      child: const MyApp(),
    ),
  );
}

/// Firebase initialization function
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
    final loginProvider = context.watch<LoginProvider>();

    // If user NOT logged in, go straight to login flow:
    if (!loginProvider.isLoggedIn || loginProvider.userId == null) {
      return MaterialApp(
        title: 'Your App Name',
        theme: _buildTheme(),
        home: const OnboardingScreen(),  // Show OnboardingScreen
        routes: {
          '/login': (context) => LoginScreen(),  // Provide a route to login
          '/onboarding': (context) => OnboardingScreen(),
          '/register': (context) => RegisterScreen(),
          '/forgot-password': (context) => ForgotPasswordScreen(),
        },
      );
    }

    // Otherwise, user is logged in => safe to use `userId` in Firestore paths
    print("Navigating to TimelineScreen with userId: ${loginProvider.userId}");

    // Provide the PreparationProvider for all child widgets:
    return ChangeNotifierProvider<PreparationProvider>(
      create: (_) => PreparationProvider(
        userId: loginProvider.userId!,
        prepService: PreparationCourseService(FirebaseFirestore.instance),
      ),
      child: MaterialApp(
        title: 'Your App Name',
        theme: _buildTheme(),
        home: TimelineScreen(),
        // We'll define an onGenerateRoute to handle e.g. '/day_detail'.
        onGenerateRoute: (settings) {
          // Example: If we do a named push with `Navigator.pushNamed('/day_detail', arguments: {...})`.
          if (settings.name == '/day_detail') {
            final args = settings.arguments as Map<String, dynamic>;
            final int dayNumber = args['dayNumber'] as int;
            final bool isDayCompleted = args['isDayCompleted'] as bool;

            return MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider<DayDetailProvider>(
                create: (_) => DayDetailProvider(
                  dayNumber: dayNumber,
                  isDayCompletedInitially: isDayCompleted,
                  firestoreInstance: FirebaseFirestore.instance,
                  userId: loginProvider.userId!,
                ),
                child: DayDetailScreen(
                  dayNumber: dayNumber,
                  isDayCompleted: isDayCompleted,
                ),
              ),
            );
          }

          // Another route example:
          if (settings.name == '/profile_screen') {
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (context) => ProfileScreen(
                userId: args['userId']!,
                loggedInUserId: args['loggedInUserId']!,
              ),
            );
          }

          return null; // Unknown route => returns null => fallback.
        },
        routes: {
          '/onboarding': (context) => OnboardingScreen(),
          '/register': (context) => RegisterScreen(),
          '/forgot-password': (context) => ForgotPasswordScreen(),
          '/timeline': (context) => TimelineScreen(),
          '/edit_profile': (context) => EditProfileScreen(),
          '/my_retreat': (context) => MyRetreatScreen(),
          '/retreat_info': (context) => RetreatInfoScreen(),
          '/preparation': (context) => PreparationCourseScreen(),
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFFEFF3F7),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 24),
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }
}
