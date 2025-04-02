import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../viewmodels/profile_viewmodel.dart';
import 'edit_profile_screen.dart';
import '../../widgets/app_drawer.dart';
import '../../services/login_provider.dart';
import '../../services/ai_gallery_service.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final String loggedInUserId;

  const ProfileScreen({
    required this.userId,
    required this.loggedInUserId,
    Key? key,
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Random _random = Random();
  final Map<String, double> _cachedHeights = {};
  bool showLikedImages = true;
  bool _isLoadingImages = false;
  final AiGalleryService _aiGalleryService = AiGalleryService();

  // Create a dedicated ProfileViewModel for this screen
  late ProfileViewModel _profileViewModel;

  @override
  void initState() {
    super.initState();
    // Log IDs for debugging
    print('ProfileScreen initialized with userId: ${widget.userId}, loggedInUserId: ${widget.loggedInUserId}');

    // Create a dedicated instance of ProfileViewModel
    _profileViewModel = ProfileViewModel();
    _profileViewModel.fetchUserProfile(widget.userId);
  }

  @override
  void dispose() {
    // Dispose of the dedicated ProfileViewModel when the screen is closed
    _profileViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const String defaultAvatarUrl =
        'https://firebasestorage.googleapis.com/v0/b/numinousway.firebasestorage.app/o/profile_images%2Fdefault_avatar.png?alt=media&token=d6afd74a-433c-4713-b8fc-73ffaa18d49c';

    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F7),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A0DAD), Color(0xFF3700B3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: ChangeNotifierProvider.value(
        // Use the local ProfileViewModel instance
        value: _profileViewModel,
        child: Consumer<ProfileViewModel>(
          builder: (context, profileVM, _) {
            // If still loading and no cached data > show spinner
            if (profileVM.isLoading && profileVM.userProfile == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final userProfile = profileVM.userProfile;
            if (userProfile == null) {
              return const Center(
                child: Text("Profile not found or failed to load."),
              );
            }

            return Column(
              children: [
                const SizedBox(height: 20),
                _buildAvatarSection(profileVM, userProfile, defaultAvatarUrl),
                const SizedBox(height: 16),
                Text(
                  userProfile.name ?? 'User Name',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 20),
                _buildToggleButtons(),
                Divider(
                  thickness: 1.2,
                  color: Colors.grey[400],
                  height: 32,
                  indent: 20,
                  endIndent: 20,
                ),
                Expanded(
                  child: _buildImageSection(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildGradientButton("Liked", showLikedImages, () {
          setState(() {
            showLikedImages = true;
            _isLoadingImages = true; // Set loading state when switching
          });
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _isLoadingImages = false;
              });
            }
          });
        }),
        const SizedBox(width: 10),
        _buildGradientButton("Generated", !showLikedImages, () {
          setState(() {
            showLikedImages = false;
            _isLoadingImages = true; // Set loading state when switching
          });
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _isLoadingImages = false;
              });
            }
          });
        }),
      ],
    );
  }

  Widget _buildGradientButton(String text, bool isSelected, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
          colors: [Color(0xFF6A0DAD), Color(0xFF3700B3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? null
            : Border.all(color: const Color(0xFF6A0DAD), width: 1.5),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: isSelected ? Colors.white : const Color(0xFF6A0DAD),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isSelected ? 8 : 0,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(
      ProfileViewModel profileVM,
      dynamic userProfile,
      String defaultAvatarUrl,
      ) {
    // Get profile image URL from userProfile
    final String imageUrl = userProfile.profileImageUrl ?? defaultAvatarUrl;

    // Get the current auth state from the provider for double verification
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final currentAuthUserId = loginProvider.userId;

    // Debug logging
    print('ProfileScreen - Build Avatar Section');
    print('  Profile ID: ${userProfile.id}');
    print('  Widget userId: ${widget.userId}');
    print('  Widget loggedInUserId: ${widget.loggedInUserId}');
    print('  Current Auth userId: $currentAuthUserId');

    // Check passed parameters match
    final bool isOwnProfile = widget.userId == currentAuthUserId;

    print('  Is own profile? $isOwnProfile');

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 70,
          backgroundColor: const Color(0xFFA785D3),
          child: CircleAvatar(
            radius: 65,
            backgroundColor: Colors.grey[200],
            child: ClipOval(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: 130,
                height: 130,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading profile image: $error');
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
        // Only show edit button if all security checks pass
        if (isOwnProfile)
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditProfileScreen()),
                );
                // re-fetch profile if updated
                profileVM.fetchUserProfile(widget.userId);
              },
              child: const CircleAvatar(
                backgroundColor: Color(0xFF6A0DAD),
                radius: 20,
                child: Icon(Icons.edit, color: Colors.white, size: 18),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageSection() {
    if (_isLoadingImages) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show "Liked" or "Generated" images based on showLikedImages
    final query = showLikedImages
        ? FirebaseFirestore.instance
        .collection('ai_images')
        .where('likes', arrayContains: widget.userId)
        .orderBy('createdAt', descending: true)
        : FirebaseFirestore.instance
        .collection('ai_images')
        .where('userId', isEqualTo: widget.userId)
        .orderBy('createdAt', descending: true);

    return _buildImagesGrid(
      query.snapshots(),
      emptyLabel:
      showLikedImages ? "No Liked Images yet." : "No Generated Images yet.",
    );
  }

  Widget _buildImagesGrid(
      Stream<QuerySnapshot> stream, {
        required String emptyLabel,
      }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        // Add more detailed error handling
        if (snapshot.hasError) {
          print('Error in stream: ${snapshot.error}');
          return Center(
            child: Text('Error loading images: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Text(
              emptyLabel,
              style: const TextStyle(
                color: Color(0xFF757575),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        return MasonryGridView.count(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final docId = doc.id;

            // Add null checks for data fields
            final imageUrl = data['thumbnailUrl'] as String? ?? data['imageUrl'] as String? ?? '';
            final prompt = data['prompt'] as String? ?? '';
            final creatorUserId = data['userId'] as String? ?? '';
            final userName = data['userName'] as String? ?? 'Unknown';
            final likes = List<String>.from(data['likes'] ?? []);
            final bool isLiked = widget.loggedInUserId != null && likes.contains(widget.loggedInUserId);

            // Random tile height, cached by docId
            final double tileHeight = _cachedHeights.putIfAbsent(
              docId,
                  () => (100 + _random.nextInt(100)).toDouble(),
            );

            return GestureDetector(
              onTap: () {
                // Show image details overlay in a light theme
                _showImageDetails(
                    context,
                    docId,
                    data['detailUrl'] as String? ?? imageUrl,
                    prompt,
                    userName,
                    creatorUserId,
                    likes.length,
                    isLiked
                );
              },
              child: Container(
                height: tileHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image: $error');
                      return Container(
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image, size: 48),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showImageDetails(
      BuildContext context,
      String docId,
      String imageUrl,
      String prompt,
      String userName,
      String creatorUserId,
      int likesCount,
      bool isLiked
      ) {
    String displayPrompt = prompt;
    String? appliedFilter;

    if (prompt.contains('[') && prompt.contains(']')) {
      final startIndex = prompt.lastIndexOf('[');
      final endIndex = prompt.lastIndexOf(']') + 1;
      if (startIndex < endIndex) {
        appliedFilter = prompt.substring(startIndex + 1, endIndex - 1);
        // Remove the filter from the display prompt
        displayPrompt = prompt.replaceRange(startIndex, endIndex, '').trim();
      }
    }

    // Log navigating to another profile for debugging
    if (creatorUserId != widget.userId) {
      print('Viewing creator profile: userId=$creatorUserId, loggedInUser=${widget.loggedInUserId}');
    }

    final bool isCreator = widget.loggedInUserId == creatorUserId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 160),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image with filter badge and delete option
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Hero(
                            tag: docId,
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        ),
                        // Show filter badge on the image if filter was applied
                        if (appliedFilter != null)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: _buildFilterBadge(appliedFilter),
                          ),
                        // Delete button for creator
                        if (isCreator)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: GestureDetector(
                              onTap: () => _showDeleteConfirmation(context, docId),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ],
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Creator profile with clickable user info
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(creatorUserId).snapshots(),
                      builder: (context, snapshot) {
                        // Default to the passed userName if we can't get data from Firestore
                        String displayName = userName;
                        String? profileImageUrl;

                        //  use the name from Firestore
                        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                          final userData = snapshot.data!.data() as Map<String, dynamic>?;
                          if (userData != null) {
                            if (userData['name'] != null) {
                              displayName = userData['name'] as String;
                            }
                            if (userData['profileImageUrl'] != null) {
                              profileImageUrl = userData['profileImageUrl'] as String;
                            }
                          }
                        }

                        return GestureDetector(
                          onTap: () {
                            if (widget.loggedInUserId != null && creatorUserId != widget.userId) {
                              // Log navigation for debugging
                              print('Navigating to creator profile: $creatorUserId, loggedInUser: ${widget.loggedInUserId}');

                              // Get the current auth state for security check
                              final loginProvider = Provider.of<LoginProvider>(context, listen: false);
                              final currentAuthUserId = loginProvider.userId;

                              // Create a new instance of the profile screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileScreen(
                                    userId: creatorUserId,
                                    loggedInUserId: currentAuthUserId ?? '',
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // User avatar
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: const Color(0xFF6A0DAD),
                                  child: CircleAvatar(
                                    radius: 26,
                                    backgroundImage: profileImageUrl != null
                                        ? NetworkImage(profileImageUrl)
                                        : null,
                                    child: profileImageUrl == null
                                        ? const Icon(Icons.person, size: 30, color: Colors.white)
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Created by',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        displayName,
                                        style: const TextStyle(
                                          color: Color(0xFF333333),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (creatorUserId != widget.userId)
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.grey,
                                    size: 16,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Likes counter only (no interactive button)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.grey[600],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$likesCount ${likesCount == 1 ? 'like' : 'likes'}',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isLiked) const Spacer(),
                          if (isLiked)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.pink[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.pink[200]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.pink,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'You liked this',
                                    style: TextStyle(
                                      color: Colors.pink,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Prompt
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prompt',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            displayPrompt,
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBadge(String filter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getFilterColor(filter),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getFilterIcon(filter),
            color: _getFilterColor(filter),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            filter,
            style: TextStyle(
              color: _getFilterColor(filter),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'Mystic Glow':
        return Colors.purple;
      case 'Nature Vibes':
        return Colors.green;
      case 'Psychedelic Burst':
        return Colors.orange;
      case 'Zen Serenity':
        return Colors.teal;
      default:
        return Colors.purple;
    }
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'Mystic Glow':
        return FontAwesomeIcons.moon;
      case 'Nature Vibes':
        return FontAwesomeIcons.leaf;
      case 'Psychedelic Burst':
        return FontAwesomeIcons.palette;
      case 'Zen Serenity':
        return FontAwesomeIcons.spa;
      default:
        return FontAwesomeIcons.wandSparkles;
    }
  }

  void _showDeleteConfirmation(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Image',
          style: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete this image? This action cannot be undone.',
          style: TextStyle(color: Color(0xFF555555)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6A0DAD)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteImage(context, docId);
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.red[50],
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        elevation: 5,
      ),
    );
  }

  Future<void> _deleteImage(BuildContext context, String docId) async {
    try {
      await _aiGalleryService.deleteAiImage(docId);
      Navigator.pop(context); // Close the bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image deleted successfully'),
          backgroundColor: Color(0xFF6A0DAD),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}