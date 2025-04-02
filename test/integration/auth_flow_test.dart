import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


class TestLoginScreen extends StatelessWidget {
  final Function(String, String)? onLogin;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onRegister;

  const TestLoginScreen({
    Key? key,
    this.onLogin,
    this.onForgotPassword,
    this.onRegister,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Hello Again",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              key: const Key('email_field'),
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('password_field'),
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onForgotPassword,
                child: const Text("Forgot password?"),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('login_button'),
                onPressed: () => onLogin?.call("test@example.com", "password123"),
                child: const Text("Login"),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: onRegister,
              child: const Text("Don't have an account? Register Now"),
            ),
          ],
        ),
      ),
    );
  }
}

class TestRegisterScreen extends StatelessWidget {
  final Function(String, String, String, String)? onRegister;
  final VoidCallback? onBackToLogin;

  const TestRegisterScreen({
    Key? key,
    this.onRegister,
    this.onBackToLogin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Create Account",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              key: const Key('name_field'),
              decoration: const InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('email_field'),
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('password_field'),
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('confirm_password_field'),
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Confirm Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              key: const Key('signup_button'),
              onPressed: () => onRegister?.call(
                  "John Doe",
                  "test@example.com",
                  "password123",
                  "password123"
              ),
              child: const Text("Register"),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onBackToLogin,
              child: const Text("Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}

class TestForgotPasswordScreen extends StatelessWidget {
  final Function(String)? onResetPassword;
  final VoidCallback? onBackToLogin;

  const TestForgotPasswordScreen({
    Key? key,
    this.onResetPassword,
    this.onBackToLogin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Reset Your Password",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              key: const Key('reset_email_field'),
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              key: const Key('send_reset_button'),
              onPressed: () => onResetPassword?.call("test@example.com"),
              child: const Text("Send Reset Link"),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onBackToLogin,
              child: const Text("Back to Login"),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple app that simulates navigation between auth screens
class TestAuthApp extends StatefulWidget {
  const TestAuthApp({Key? key}) : super(key: key);

  @override
  _TestAuthAppState createState() => _TestAuthAppState();
}

class _TestAuthAppState extends State<TestAuthApp> {
  String _currentScreen = 'login';
  bool _isLoggedIn = false;
  String? _verificationMessage;

  void _login(String email, String password) {
    // Simulate login success
    setState(() {
      if (email == "test@example.com" && password == "password123") {
        _isLoggedIn = true;
      } else {
        _verificationMessage = "Invalid email or password";
      }
    });
  }

  void _register(String name, String email, String password, String confirmPassword) {
    // Simulate registration + verification email
    setState(() {
      _verificationMessage = "Verification email sent to $email";
      _currentScreen = 'verification';
    });
  }

  void _resetPassword(String email) {
    // Simulate password reset
    setState(() {
      _verificationMessage = "Password reset link sent to $email";
      _currentScreen = 'reset_confirmation';
    });
  }

  void _navigateTo(String screen) {
    setState(() {
      _currentScreen = screen;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text("Home")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Welcome to the app!", style: TextStyle(fontSize: 24)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoggedIn = false;
                    _currentScreen = 'login';
                  });
                },
                child: const Text("Logout"),
              ),
            ],
          ),
        ),
      );
    }

    switch (_currentScreen) {
      case 'login':
        return TestLoginScreen(
          onLogin: _login,
          onForgotPassword: () => _navigateTo('forgot_password'),
          onRegister: () => _navigateTo('register'),
        );
      case 'register':
        return TestRegisterScreen(
          onRegister: _register,
          onBackToLogin: () => _navigateTo('login'),
        );
      case 'forgot_password':
        return TestForgotPasswordScreen(
          onResetPassword: _resetPassword,
          onBackToLogin: () => _navigateTo('login'),
        );
      case 'verification':
        return Scaffold(
          appBar: AppBar(title: const Text("Verify Email")),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Verify Your Email",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(_verificationMessage ?? ""),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _navigateTo('login'),
                  child: const Text("Back to Login"),
                ),
              ],
            ),
          ),
        );
      case 'reset_confirmation':
        return Scaffold(
          appBar: AppBar(title: const Text("Reset Password")),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Password Reset Email Sent",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(_verificationMessage ?? ""),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _navigateTo('login'),
                  child: const Text("Back to Login"),
                ),
              ],
            ),
          ),
        );
      default:
        return const TestLoginScreen();
    }
  }
}

void main() {
  testWidgets('Full authentication flow test', (WidgetTester tester) async {
    // Build  app and trigger a frame
    await tester.pumpWidget(const MaterialApp(home: TestAuthApp()));

    //  login screen
    expect(find.text('Hello Again'), findsOneWidget);

    // Navigate to registration
    await tester.tap(find.text("Don't have an account? Register Now"));
    await tester.pumpAndSettle();


    expect(find.text('Create Account'), findsOneWidget);

    // registration form
    await tester.enterText(find.byKey(const Key('name_field')), 'John Doe');
    await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'password123');
    await tester.enterText(find.byKey(const Key('confirm_password_field')), 'password123');

    // Submit registration form
    await tester.tap(find.byKey(const Key('signup_button')));
    await tester.pumpAndSettle();

    // Verify the verification screen
    expect(find.text('Verify Your Email'), findsOneWidget);
    expect(find.text('Verification email sent to test@example.com'), findsOneWidget);

    // Go back to login
    await tester.tap(find.text('Back to Login'));
    await tester.pumpAndSettle();

    // Verify  back on login screen
    expect(find.text('Hello Again'), findsOneWidget);

    // Test forgot password f
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    // Verify  forgot password screen
    expect(find.text('Reset Your Password'), findsOneWidget);

    // Enter email and submit
    await tester.enterText(find.byKey(const Key('reset_email_field')), 'test@example.com');
    await tester.tap(find.byKey(const Key('send_reset_button')));
    await tester.pumpAndSettle();

    // Verify confirmation screen
    expect(find.text('Password Reset Email Sent'), findsOneWidget);

    // Go back to login
    await tester.tap(find.text('Back to Login'));
    await tester.pumpAndSettle();

    // Verify on login screen
    expect(find.text('Hello Again'), findsOneWidget);

    // Test successful login
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();

    // Verify logged in
    expect(find.text('Welcome to the app!'), findsOneWidget);

    // Test logout
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    // Verify back on login screen
    expect(find.text('Hello Again'), findsOneWidget);
  });
}