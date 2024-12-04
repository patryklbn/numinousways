// post_widget.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/timeline_service.dart';
import '../../models/post.dart';
import '../../models/user_profile.dart';
import '../../services/profile_service.dart';
import '../../screens/comments/comments_screen.dart';
import '../../screens/profile/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/login_provider.dart';

class PostWidget extends StatelessWidget {
  final Post post;
  final ValueNotifier<bool> isCommentsScreenOpen;

  const PostWidget({Key? key, required this.post, required this.isCommentsScreenOpen}) : super(key: key);

  Future<UserProfile?> _fetchUserProfile(String userId) async {
    ProfileService profileService = ProfileService();
    return await profileService.getUserProfile(userId);
  }

  @override
  Widget build(BuildContext context) {
    final TimelineService timelineService = TimelineService();
    final LoginProvider loginProvider = Provider.of<LoginProvider>(context, listen: false);
    String? currentUserId = loginProvider.userId;

    return FutureBuilder<UserProfile?>(
      future: _fetchUserProfile(post.userId),
      builder: (context, snapshot) {
        UserProfile? user = snapshot.data;
        return Card(
          color: Colors.white, // Set the background color to pure white
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info and Timestamp
              ListTile(
                leading: GestureDetector(
                  onTap: () {
                    // Navigate to user's profile
                    if (currentUserId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            userId: post.userId,
                            loggedInUserId: currentUserId,
                          ),
                        ),
                      );
                    }
                  },
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFBA8FDB),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundImage: user?.profileImageUrl != null
                          ? NetworkImage(user!.profileImageUrl!)
                          : null,
                      child: user?.profileImageUrl == null
                          ? const Icon(Icons.person, size: 30, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
                title: GestureDetector(
                  onTap: () {
                    // Navigate to user's profile
                    if (currentUserId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            userId: post.userId,
                            loggedInUserId: currentUserId,
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    user?.name ?? 'No Name',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                subtitle: Text(
                  timeago.format(post.createdAt.toDate()),
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              ),
              // Post Content
              if (post.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    post.content,
                    style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
                  ),
                ),
              const SizedBox(height: 10),
              // Post Image
              if (post.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: post.imageUrl!,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.broken_image)),
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              // Actions: Like and Comment
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    // Like Button
                    GestureDetector(
                      onTap: () async {
                        if (currentUserId != null) {
                          await timelineService.toggleLike(post.id, currentUserId);
                        }
                      },
                      child: Row(
                        children: [
                          Icon(
                            post.isLiked ? Icons.favorite : Icons.favorite_border,
                            color: post.isLiked ? Colors.red : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.likesCount}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Comment Button
                    ValueListenableBuilder<bool>(
                      valueListenable: isCommentsScreenOpen,
                      builder: (context, isDisabled, _) {
                        return GestureDetector(
                          onTap: isDisabled
                              ? null
                              : () {
                            // Navigate to comments screen
                            isCommentsScreenOpen.value = true; // Disable button while navigating
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CommentsScreen(postId: post.id),
                              ),
                            ).then((_) {
                              // Reactivate button when coming back
                              isCommentsScreenOpen.value = false;
                            });
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.comment_outlined,
                                color: isDisabled ? Colors.grey[400] : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post.commentsCount}',
                                style: TextStyle(
                                  color: isDisabled ? Colors.grey[400] : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
