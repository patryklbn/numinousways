import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:numinous_ways/screens/privacy_policy.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Firebase config
import 'firebase_options.dart';

// Screens
import 'screens/ai_gallery/ai_gallery_screen.dart';
import 'screens/ai_gallery/ai_prompt_screen.dart';
import 'screens/my_retreat/integration/integration_detail_screen.dart';
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
import 'screens/my_retreat/integration/integration_course_screen.dart';
import 'screens/my_retreat/experience/experience_main_screen.dart';

// ViewModels / Providers
import 'services/integration_course_service.dart';
import 'services/login_provider.dart';
import 'services/myretreat_service.dart';
import 'services/firestore_service.dart';
import 'services/retreat_service.dart';
import 'services/storage_service.dart';
import 'viewmodels/integration_provider.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'services/notification_service.dart';
import 'services/preparation_course_service.dart';
import 'viewmodels/preparation_provider.dart';
import 'viewmodels/day_detail_provider.dart';
import 'viewmodels/integration_day_detail_provider.dart';
import 'viewmodels/experience_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  await initializeFirebase();

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(
    MultiProvider(
      providers: [
        // Notification Service
        Provider<NotificationService>.value(value: notificationService),

        // Profile ViewModel
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),

        // Login Provider
        ChangeNotifierProvider(create: (_) => LoginProvider()),

        // MyRetreat Service
        Provider(
          create: (_) => MyRetreatService(
            firestoreService: FirestoreService(),
            storageService: StorageService(),
          ),
        ),

        // Retreat Service provider
        Provider<RetreatService>(create: (_) => RetreatService()),

        // Experience Provider
        ChangeNotifierProxyProvider<LoginProvider, ExperienceProvider>(
          create: (context) => ExperienceProvider(
            retreatService: context.read<RetreatService>(),
            userId: context.read<LoginProvider>().userId,
          ),
          update: (context, loginProvider, experienceProvider) =>
              ExperienceProvider(
                retreatService: context.read<RetreatService>(),
                userId: loginProvider.userId,
              ),
        ),

        // Integration Provider
        ChangeNotifierProxyProvider<LoginProvider, IntegrationProvider>(
          create: (context) => IntegrationProvider(
            userId: context.read<LoginProvider>().userId ?? '',
            integrationService: IntegrationCourseService(FirebaseFirestore.instance),
          ),
          update: (context, loginProvider, _) => IntegrationProvider(
            userId: loginProvider.userId ?? '',
            integrationService: IntegrationCourseService(FirebaseFirestore.instance),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

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
    final user = loginProvider.user;

    // Debug print to help diagnose issues
    print("Current user: ${user?.email}, Verified: ${user?.emailVerified}");

    // Create ALL routes that will be available throughout the app
    final Map<String, Widget Function(BuildContext)> allRoutes = {
      // Auth and Common Routes
      '/login': (context) => const LoginScreen(),
      '/onboarding': (context) => const OnboardingScreen(),
      '/register': (context) => const RegisterScreen(),
      '/forgot-password': (context) => const ForgotPasswordScreen(),
      '/timeline': (context) => const TimelineScreen(),

      // Main App Routes
      '/my_retreat': (context) => const MyRetreatScreen(),
      '/preparation': (context) => PreparationCourseScreen(),
      '/experience': (context) => const ExperienceMainScreen(),
      '/integration': (context) => IntegrationCourseScreen(),
      '/ai_gallery': (context) => const AiGalleryScreen(),
      '/ai_prompt': (context) => const AiPromptScreen(),
      '/privacy_policy': (context) => const PrivacyPolicyScreen(),
      '/edit_profile': (context) => EditProfileScreen(),

      // Profile route with parameters
      '/profile_screen': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return ProfileScreen(
          userId: args?['userId'] as String? ?? user?.uid ?? '',
          loggedInUserId: args?['loggedInUserId'] as String? ?? user?.uid ?? '',
        );
      },
    };

    // Determine home screen based on authentication and verification status
    Widget homeScreen;

    if (user == null) {
      // Not logged in
      homeScreen = const OnboardingScreen();
    } else if (!user.emailVerified) {
      // Logged in but not verified
      homeScreen = const LoginScreen();
    } else {
      // Logged in and verified
      homeScreen = const TimelineScreen();
    }

    // Create a single MaterialApp with conditional providers as needed
    return user != null && user.emailVerified
        ? ChangeNotifierProvider<PreparationProvider>(
      // Only add this provider for verified users
      create: (_) => PreparationProvider(
        userId: loginProvider.userId!,
        prepService: PreparationCourseService(FirebaseFirestore.instance),
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Your App Name',
        theme: _buildTheme(),
        home: homeScreen,
        routes: allRoutes,
        onGenerateRoute: (settings) {
          // Preparation day detail route
          if (settings.name == '/day_detail') {
            final args = settings.arguments as Map<String, dynamic>?;
            final int dayNumber = args?['dayNumber'] as int? ?? 1;
            final bool isDayCompleted = args?['isDayCompleted'] as bool? ?? false;

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

          // Integration day detail route
          if (settings.name == '/integration_day_detail') {
            final args = settings.arguments as Map<String, dynamic>?;
            final int dayNumber = args?['dayNumber'] as int? ?? 1;
            final bool isDayCompleted = args?['isDayCompleted'] as bool? ?? false;

            return MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider<IntegrationDayDetailProvider>(
                create: (_) => IntegrationDayDetailProvider(
                  dayNumber: dayNumber,
                  isDayCompletedInitially: isDayCompleted,
                  firestoreInstance: FirebaseFirestore.instance,
                  userId: loginProvider.userId!,
                ),
                child: IntegrationDayDetailScreen(
                  dayNumber: dayNumber,
                  isDayCompleted: isDayCompleted,
                ),
              ),
            );
          }

          return null;
        },
      ),
    )
        : MaterialApp(
      debugShowCheckedModeBanner: false,
      // MaterialApp for non-verified users
      title: 'Your App Name',
      theme: _buildTheme(),
      home: homeScreen,
      routes: allRoutes,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFFEFF3F7),
      textTheme: GoogleFonts.robotoTextTheme(
        ThemeData.light().textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 24),
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }
}