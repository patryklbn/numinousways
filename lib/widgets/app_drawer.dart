// lib/widgets/app_drawer.dart

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

  @override
  Widget build(BuildContext context) {
    final loginProvider = Provider.of<LoginProvider>(context);
    final profileViewModel = Provider.of<ProfileViewModel>(context);
    final String loggedInUserId = loginProvider.userId ?? '';

    final isLoading = profileViewModel.isLoading;
    final userProfile = profileViewModel.userProfile;
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'user@example.com';

    const String defaultAvatarUrl =
        'https://firebasestorage.googleapis.com/v0/b/yourapp.appspot.com/o/profile_images%2Fdefault_avatar.png?alt=media';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: isLoading
                ? const Text('Loading...')
                : Text(
              userProfile?.name ?? 'User Name',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: ClipOval(
                child: Image.network(
                  userProfile?.profileImageUrl ?? defaultAvatarUrl,
                  fit: BoxFit.cover,
                  width: 74,
                  height: 74,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/default_avatar.png',
                      fit: BoxFit.cover,
                      width: 74,
                      height: 74,
                    );
                  },
                ),
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
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Timeline'),
            onTap: () {
              Navigator.pushNamed(context, '/timeline');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: () {
              loginProvider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
