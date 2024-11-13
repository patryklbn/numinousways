// lib/widgets/app_drawer.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/login_provider.dart';
import '../viewmodels/profile_viewmodel.dart';

class AppDrawer extends StatefulWidget {
  final String userId;

  const AppDrawer({Key? key, required this.userId}) : super(key: key);

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  late ProfileViewModel profileViewModel;

  @override
  void initState() {
    super.initState();
    profileViewModel = Provider.of<ProfileViewModel>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (profileViewModel.userProfile == null ||
          profileViewModel.userProfile?.id != widget.userId) {
        profileViewModel.fetchUserProfile(widget.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'user@example.com';

    return Consumer<ProfileViewModel>(
      builder: (context, profileViewModel, child) {
        final userProfile = profileViewModel.userProfile;
        final isLoading = profileViewModel.isLoading;

        final String defaultAvatarUrl =
            'https://firebasestorage.googleapis.com/v0/b/numinousway.firebasestorage.app/o/profile_images%2Fdefault_avatar.png?alt=media&token=d6afd74a-433c-4713-b8fc-73ffaa18d49c';

        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: isLoading
                    ? Text('Loading...')
                    : Text(
                  userProfile?.name ?? 'User Name',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(userEmail),
                currentAccountPicture: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFAD3D6F), // External circle color
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3.0), // Border thickness
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white, // Inner circle color
                      ),
                      child: ClipOval(
                        child: userProfile?.profileImageUrl != null
                            ? Image.network(
                          userProfile!.profileImageUrl!,
                          fit: BoxFit.cover,
                          width: 74,
                          height: 74,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to local asset on error
                            return Image.asset(
                              'assets/default_avatar.png',
                              fit: BoxFit.cover,
                              width: 74,
                              height: 74,
                            );
                          },
                        )
                            : Image.asset(
                          'assets/default_avatar.png',
                          fit: BoxFit.cover,
                          width: 74,
                          height: 74,
                        ),
                      ),
                    ),
                  ),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6A0DAD), Color(0xFF3700B3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.home),
                title: Text('Timeline'),
                onTap: () {
                  Navigator.pushNamed(context, '/timeline');
                },
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Profile'),
                onTap: () {
                  Navigator.pushNamed(context, '/profile_screen', arguments: {
                    'userId': widget.userId,
                    'loggedInUserId': widget.userId,
                  });
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Log Out'),
                onTap: () {
                  Provider.of<LoginProvider>(context, listen: false).logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
