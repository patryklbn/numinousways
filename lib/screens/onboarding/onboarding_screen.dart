import 'package:flutter/material.dart';
import '../../models/onboarding_page_model.dart';
import '../../widgets/onboarding_page_presenter.dart';
import '../login/login_screen.dart'; // Import your login screen

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  void _onSkip(BuildContext context) {
    // Navigate to login screen or any other screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _onFinish(BuildContext context) {
    // Navigate to login screen or any other screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OnboardingPagePresenter(
        pages: [
          OnboardingPageModel(
            title: 'Welcome to Numinous Ways',
            textColor: Colors.black,
            description: 'Your journey to connection, growth, and mindfulness starts here.',
            imageAsset: 'assets/images/onboarding-0.png', // Local image
            bgColor: Colors.white,
          ),
          OnboardingPageModel(
            title: 'Connect and Engage with the Community',
            description: 'Stay connected with like-minded individuals, share experiences, and support each other.',
            imageAsset: 'assets/images/onboarding-1.png', // Updated to use local image
            bgColor: const Color(0xFF323F83),
          ),
          OnboardingPageModel(
            title: 'Continue Your Mindfulness Journey',
            description: 'Access guided meditations and practices to help you sustain peace and mindfulness.',
            imageAsset: 'assets/images/onboarding-3.png', // Network image
            bgColor: const Color(0xFF1F5D52),
          ),
          OnboardingPageModel(
            title: 'Create and Share Your Moments',
            description: 'Share your experiences and connect through posts and photos.',
            imageAsset: 'assets/images/onboarding-2a.png', // Network image
            bgColor: const Color(0xFFFCC572),
          ),
        ],
        onSkip: () => _onSkip(context),
        onFinish: () => _onFinish(context),
      ),
    );
  }
}
