import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../viewmodels/profile_viewmodel.dart';
import 'edit_profile_screen.dart';
import '../../widgets/app_drawer.dart'; // Import the AppDrawer

class ProfileScreen extends StatefulWidget {
  final String userId;
  final String loggedInUserId;

  ProfileScreen({required this.userId, required this.loggedInUserId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileViewModel profileViewModel;
  bool showLikedImages = true;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    profileViewModel = Provider.of<ProfileViewModel>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      profileViewModel.fetchUserProfile(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    const String defaultAvatarUrl = 'https://firebasestorage.googleapis.com/v0/b/numinousway.firebasestorage.app/o/profile_images%2Fdefault_avatar.png?alt=media&token=d6afd74a-433c-4713-b8fc-73ffaa18d49c';

    return Scaffold(
      backgroundColor: Color(0xFFEFF3F7),
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A0DAD), Color(0xFF3700B3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      drawer: AppDrawer(userId: widget.userId), // Include the drawer here
      body: Consumer<ProfileViewModel>(
        builder: (context, profileViewModel, child) {
          if (profileViewModel.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          final userProfile = profileViewModel.userProfile;
          if (userProfile == null) {
            return Center(child: Text("Profile not found or failed to load."));
          }

          return Column(
            children: [
              SizedBox(height: 20),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Color(0xFFBA8FDB),

                child: CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.grey[200],
                      child: ClipOval(
                        child: Image.network(
                          profileViewModel.profileImageUrl ?? defaultAvatarUrl,
                          fit: BoxFit.cover,
                          width: 130,
                          height: 130,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/default_avatar.png',
                              fit: BoxFit.cover,
                              width: 130,
                              height: 130,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (widget.userId == widget.loggedInUserId)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(),
                            ),
                          ).then((_) {
                            profileViewModel.fetchUserProfile(widget.userId);
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: Color(0xFF6A0DAD),
                          radius: 20,
                          child: Icon(Icons.edit, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                userProfile.name ?? 'User Name',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildGradientButton("Liked", showLikedImages, () {
                    setState(() {
                      showLikedImages = true;
                    });
                  }),
                  SizedBox(width: 10),
                  _buildGradientButton("Generated", !showLikedImages, () {
                    setState(() {
                      showLikedImages = false;
                    });
                  }),
                ],
              ),
              Divider(
                thickness: 1.2,
                color: Colors.grey[400],
                height: 32,
                indent: 20,
                endIndent: 20,
              ),
              Expanded(
                child: showLikedImages
                    ? _buildMasonryGrid("Liked images will appear here")
                    : _buildMasonryGrid("Generated images will appear here"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGradientButton(String text, bool isSelected, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
          colors: [Color(0xFF6A0DAD), Color(0xFF3700B3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? null
            : Border.all(color: Color(0xFF6A0DAD), width: 1.5),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: isSelected ? Colors.white : Color(0xFF6A0DAD),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isSelected ? 8 : 0,
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildMasonryGrid(String placeholderText) {
    return MasonryGridView.count(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: 20,
      itemBuilder: (context, index) {
        final randomHeight = 100 + random.nextInt(100);

        return Container(
          height: randomHeight.toDouble(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(2, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              placeholderText,
              style: TextStyle(
                color: Color(0xFF757575),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
