import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/login_provider.dart';
import '../viewmodels/profile_viewmodel.dart';

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
        profileViewModel.fetchUserProfile(loginProvider.userId!);
      }
    });
  }

  Future<void> _logout(BuildContext context) async {
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);

    // Perform logout
    await loginProvider.logout();

    // Navigate to Onboarding Screen and clear navigation stack
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/onboarding',
          (Route<dynamic> route) => false,
    );
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

    const String defaultAvatarUrl =
        'https://firebasestorage.googleapis.com/v0/b/yourapp.appspot.com/o/profile_images%2Fdefault_avatar.png?alt=media';

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
              currentAccountPicture: CircleAvatar(
                radius: 36, // Outer circle
                  backgroundColor: const Color(0xFFA785D3),
                 // Neutral white color for the border
                child: CircleAvatar(
                  radius: 34, // Inner circle with the actual image
                  backgroundColor: Colors.grey[200], // Fallback color
                  backgroundImage: NetworkImage(userProfile?.profileImageUrl ?? defaultAvatarUrl),
                  child: userProfile?.profileImageUrl == null
                      ? const Icon(Icons.person, size: 36, color: Colors.grey)
                      : null,
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
                Navigator.pushNamed(context, '/timeline'); // Navigate to Timeline
              },
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('My Retreat'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.pushNamed(context, '/my_retreat'); // Navigate to My Retreat
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.pushNamed(
                  context,
                  '/profile_screen',
                  arguments: {
                    'userId': loggedInUserId,
                    'loggedInUserId': loggedInUserId,
                  },
                ); // Navigate to Profile with arguments
              },
            ),
            const Divider(), // Divider between menu items
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log Out'),
              onTap: () async {
                Navigator.pop(context); // Close drawer
                await _logout(context); // Perform logout
              },
            ),
          ],
        ),
      ),
    );
  }
}
