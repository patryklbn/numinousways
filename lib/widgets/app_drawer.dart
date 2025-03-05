import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/login_provider.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  late ProfileViewModel profileViewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loginProvider = Provider.of<LoginProvider>(context, listen: false);
      profileViewModel = Provider.of<ProfileViewModel>(context, listen: false);
      if (loginProvider.isLoggedIn) {
        final profileVM = Provider.of<ProfileViewModel>(context, listen: false);
        // This will use cached data if available, or fetch from Firestore if not
        profileVM.fetchUserProfile(loginProvider.userId!);
      }
    });
  }

  Future<void> _logout(BuildContext context) async {
    try {
      // Store context in a local variable to ensure it's captured properly
      final BuildContext capturedContext = context;

      // Get login provider
      final loginProvider = Provider.of<LoginProvider>(capturedContext, listen: false);

      // Perform logout
      await loginProvider.logout();

      // Check if the widget is still mounted before navigating
      if (!mounted) return;

      // Navigate to Onboarding Screen and clear navigation stack
      // Use the captured context to ensure it's still valid
      Navigator.of(capturedContext).pushNamedAndRemoveUntil(
        '/onboarding',
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      print('Error during logout: $e');
      // If we're still mounted, show an error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginProvider = Provider.of<LoginProvider>(context);
    final profileViewModel = Provider.of<ProfileViewModel>(context);

    final bool isLoading = profileViewModel.isLoading;
    final userProfile = profileViewModel.userProfile;
    final String loggedInUserId = loginProvider.userId ?? '';
    final String userEmail =
        FirebaseAuth.instance.currentUser?.email ?? 'user@example.com';

    return Drawer(
      child: Container(
        color: Colors.white, // Drawer background color
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header
            UserAccountsDrawerHeader(
              accountName: isLoading
                  ? const Text('Loading...')
                  : Text(
                userProfile?.name ?? 'User Name',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(userEmail),
              // Custom avatar handling
              currentAccountPicture: CircleAvatar(
                radius: 36, // Outer circle
                backgroundColor: const Color(0xFFA785D3),
                child: CircleAvatar(
                  radius: 34, // Inner circle where the image or default icon goes
                  backgroundColor: Colors.grey[200],
                  child: _buildAvatarChild(userProfile?.profileImageUrl),
                ),
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A0DAD), Color(0xFF3700B3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Menu Items
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Timeline'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.pushNamed(context, '/timeline');
              },
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('My Retreat'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/my_retreat');
              },
            ),
            ListTile(
              leading: const FaIcon(
                FontAwesomeIcons.magicWandSparkles,
                size: 18,
              ),
              title: const Text('AI Gallery'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/ai_gallery');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/profile_screen',
                  arguments: {
                    'userId': loggedInUserId,
                    'loggedInUserId': loggedInUserId,
                  },
                );
              },
            ),
            const Divider(), // Divider between menu items
            // Privacy Policy - Added here between Profile and Logout
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Policy'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.pushNamed(context, '/privacy_policy');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log Out'),
              onTap: () {
                try {
                  Navigator.pop(context); // Close drawer
                  _logout(context);
                } catch (e) {
                  print('Error during logout: $e');
                  // Just ignore any errors here
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Returns either a NetworkImage (with error fallback) or a built-in icon if there's no image.
  Widget _buildAvatarChild(String? profileImageUrl) {
    // If we have a valid profile image URL, attempt to load it
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          profileImageUrl,
          fit: BoxFit.cover,
          width: 68,
          height: 68,
          // If the image fails to load, show the default icon
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.person, size: 36, color: Colors.grey);
          },
        ),
      );
    }

    // Otherwise, show built-in default icon
    return const Icon(Icons.person, size: 36, color: Colors.grey);
  }
}