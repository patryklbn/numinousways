import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../services/login_provider.dart';
import '../../services/ai_gallery_service.dart';
import '../profile/profile_screen.dart';

class AiGalleryScreen extends StatefulWidget {
  const AiGalleryScreen({Key? key}) : super(key: key);

  @override
  State<AiGalleryScreen> createState() => _AiGalleryScreenState();
}

class _AiGalleryScreenState extends State<AiGalleryScreen> {
  final AiGalleryService _aiGalleryService = AiGalleryService();
  final Random _random = Random();
  final Map<String, double> _cachedHeights = {};
  bool _showInfoOverlay = false;

  @override
  Widget build(BuildContext context) {
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final userId = loginProvider.userId;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: _buildAppBar(context),
      floatingActionButton: _buildFloatingActionButton(context),
      body: Column(
        children: [
          _buildHeaderSection(),
          Expanded(
            child: _buildGalleryGrid(userId),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      centerTitle: true, // Center the title in the app bar
      title: Row(
        mainAxisSize: MainAxisSize.min, // Make the row take only the space it needs
        children: [
          const FaIcon(
            FontAwesomeIcons.wandMagicSparkles,
            size: 20,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          const Text(
            'AI Gallery',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
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
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          color: Colors.white,
          onPressed: () => setState(() => _showInfoOverlay = !_showInfoOverlay),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A0DAD), Color(0xFF3700B3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/ai_prompt'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.add,
          size: 28,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    if (!_showInfoOverlay) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2A3E), Color(0xFF1A1A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6A0DAD).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✨ Welcome to AI Gallery',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explore AI-generated artwork created by our community. Tap the + button to create your own!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid(String? userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _aiGalleryService.streamAllImages(),
      builder: (context, snapshot) {
        // Error handling
        if (snapshot.hasError) {
          print('Error in AI Gallery stream: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading images: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A0DAD)),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(
                  FontAwesomeIcons.wandMagicSparkles,
                  size: 48,
                  color: Color(0xFF6A0DAD),
                ),
                const SizedBox(height: 16),
                Text(
                  'No images generated yet\nBe the first to create!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        }

        // Build masonry layout
        return MasonryGridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            return _buildImageTile(docs[index], userId);
          },
        );
      },
    );
  }

  Widget _buildImageTile(DocumentSnapshot doc, String? userId) {
    final data = doc.data() as Map<String, dynamic>;
    final docId = doc.id;

    final imageUrl = data['imageUrl'] as String;
    final prompt = data['prompt'] as String? ?? '';
    final userName = data['userName'] as String? ?? 'Unknown';
    final creatorUserId = data['userId'] as String? ?? '';
    final likes = List<String>.from(data['likes'] ?? []);
    final bool isLiked = userId != null && likes.contains(userId);

    // Extract filter from prompt if it exists (format [FilterName])
    String? appliedFilter;
    if (prompt.contains('[') && prompt.contains(']')) {
      final startIndex = prompt.lastIndexOf('[') + 1;
      final endIndex = prompt.lastIndexOf(']');
      if (startIndex < endIndex) {
        appliedFilter = prompt.substring(startIndex, endIndex);
      }
    }

    // Random tile height for the masonry layout
    final tileHeight = _cachedHeights.putIfAbsent(
      docId,
          () => (200 + _random.nextInt(150)).toDouble(),
    );

    return GestureDetector(
      onTap: () => _showImageDetails(
        context,
        docId,
        imageUrl,
        prompt,
        userName,
        creatorUserId,
        likes.length,
        isLiked,
      ),
      child: Container(
        height: tileHeight,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: docId,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  // SHOW SPINNER / PLACEHOLDER WHILE LOADING
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      // Image fully loaded
                      return child;
                    }
                    // Loading in progress -> show a placeholder
                    return Container(
                      color: Colors.grey[900],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 48,
                      ),
                    );
                  },
                ),
              ),
              // Filter badge if filter applied
              if (appliedFilter != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildFilterBadge(appliedFilter),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Display the image creator's username
                      Expanded(
                        child: StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(creatorUserId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            String displayName = userName; // Fallback
                            if (snapshot.hasData &&
                                snapshot.data != null &&
                                snapshot.data!.exists) {
                              final userData =
                              snapshot.data!.data() as Map<String, dynamic>?;
                              if (userData != null &&
                                  userData['name'] != null) {
                                displayName = userData['name'] as String;
                              }
                            }
                            return Text(
                              displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          if (userId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please log in to like images'),
                                backgroundColor: Color(0xFF6A0DAD),
                              ),
                            );
                            return;
                          }
                          await _aiGalleryService.toggleLike(
                            docId: docId,
                            userId: userId,
                            currentlyLiked: isLiked,
                          );
                        },
                        child: Row(
                          children: [
                            Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              likes.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildFilterBadge(String filter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getFilterColor(filter),
          width: 1.5,
        ),
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

  void _showImageDetails(
      BuildContext context,
      String docId,
      String imageUrl,
      String prompt,
      String userName,
      String creatorUserId,
      int likesCount,
      bool isLiked,
      ) {
    // Extract filter from prompt if it exists
    String displayPrompt = prompt;
    String? appliedFilter;

    if (prompt.contains('[') && prompt.contains(']')) {
      final startIndex = prompt.lastIndexOf('[');
      final endIndex = prompt.lastIndexOf(']') + 1;
      if (startIndex < endIndex) {
        appliedFilter = prompt.substring(startIndex + 1, endIndex - 1);
        // Remove the filter text from the displayed prompt
        displayPrompt = prompt.replaceRange(startIndex, endIndex, '').trim();
      }
    }

    final LoginProvider loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final String? currentUserId = loginProvider.userId;
    final bool isCreator = currentUserId == creatorUserId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Container(
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 160),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image preview with optional filter badge & delete icon
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                        if (appliedFilter != null)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: _buildFilterBadge(appliedFilter),
                          ),
                        if (isCreator)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: GestureDetector(
                              onTap: () => _showDeleteConfirmation(context, docId),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
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
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(creatorUserId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        String displayName = userName; // fallback
                        String? profileImageUrl;

                        if (snapshot.hasData &&
                            snapshot.data != null &&
                            snapshot.data!.exists) {
                          final userData =
                          snapshot.data!.data() as Map<String, dynamic>?;
                          if (userData != null) {
                            if (userData['name'] != null) {
                              displayName = userData['name'] as String;
                            }
                            if (userData['profileImageUrl'] != null) {
                              profileImageUrl =
                              userData['profileImageUrl'] as String;
                            }
                          }
                        }

                        return GestureDetector(
                          onTap: () {
                            if (currentUserId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileScreen(
                                    userId: creatorUserId,
                                    loggedInUserId: currentUserId,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A3E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: const Color(0xFF6A0DAD),
                                  child: CircleAvatar(
                                    radius: 26,
                                    backgroundImage: profileImageUrl != null
                                        ? NetworkImage(profileImageUrl)
                                        : null,
                                    child: profileImageUrl == null
                                        ? const Icon(
                                      Icons.person,
                                      size: 30,
                                      color: Colors.white,
                                    )
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
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        displayName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white54,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Likes counter
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A3E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.white70,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$likesCount ${likesCount == 1 ? 'like' : 'likes'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
                        color: const Color(0xFF2A2A3E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prompt',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            displayPrompt,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
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

  void _showDeleteConfirmation(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text(
          'Delete Image',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this image? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteImage(context, docId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
