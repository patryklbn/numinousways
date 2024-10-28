import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this to use User class

void main() async {
  // Ensure that Flutter is properly initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // After Firebase is initialized, run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Auth Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const FirebaseInitChecker(),
    );
  }
}

class FirebaseInitChecker extends StatefulWidget {
  const FirebaseInitChecker({super.key});

  @override
  State<FirebaseInitChecker> createState() => _FirebaseInitCheckerState();
}

class _FirebaseInitCheckerState extends State<FirebaseInitChecker> {
  // This variable will store the state of Firebase initialization
  late Future<FirebaseApp> _initialization;

  @override
  void initState() {
    super.initState();
    // Initialize Firebase here and store the Future
    _initialization = Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // Use the Future created in initState
      future: _initialization,
      builder: (context, snapshot) {
        // Check for Firebase initialization errors
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Firebase Init Error"),
            ),
            body: Center(
              child: Text(
                'Error initializing Firebase: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Once complete, show the main app UI
        if (snapshot.connectionState == ConnectionState.done) {
          return const AuthPage(); // Redirect to AuthPage after Firebase is initialized
        }

        // While Firebase is being initialized, show a loading spinner
        return Scaffold(
          appBar: AppBar(
            title: const Text("Initializing Firebase"),
          ),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

// Authentication Page for Firebase Authentication Demo
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Authentication')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Email sign-in
                User? user = await _authService.signInWithEmailPassword(
                  _emailController.text,
                  _passwordController.text,
                );
                if (user != null) {
                  print('Signed in as: ${user.email}');
                }
              },
              child: const Text('Sign In with Email/Password'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Email sign-up
                User? user = await _authService.signUpWithEmailPassword(
                  _emailController.text,
                  _passwordController.text,
                );
                if (user != null) {
                  print('User signed up: ${user.email}');
                }
              },
              child: const Text('Sign Up with Email/Password'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Anonymous sign-in
                User? user = await _authService.signInAnonymously();
                if (user != null) {
                  print('Signed in anonymously with user ID: ${user.uid}');
                }
              },
              child: const Text('Sign In Anonymously'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _authService.signOut();
                print('Signed out');
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
