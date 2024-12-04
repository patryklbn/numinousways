// comment_widget.dart
import 'package:flutter/material.dart';
import '../../models/comment.dart';
import '../../models/user_profile.dart';
import '../../services/profile_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/login_provider.dart';
import 'package:provider/provider.dart';
import '../../services/timeline_service.dart';
import '../../screens/profile/profile_screen.dart';

class CommentWidget extends StatefulWidget {
  final String postId; // The ID of the post to which the comment belongs
  final Comment comment;

  const CommentWidget({
    Key? key,
    required this.postId,
    required this.comment,
  }) : super(key: key);

  @override
  _CommentWidgetState createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  late bool isLiked;
  late int likesCount;
  late String currentUserId;
  final TimelineService _timelineService = TimelineService();

  @override
  void initState() {
    super.initState();
    isLiked = widget.comment.isLiked;
    likesCount = widget.comment.likesCount;

    // Initialize currentUserId in initState
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    currentUserId = loginProvider.userId ?? '';
  }

  void _toggleLike() async {
    if (currentUserId.isEmpty) return;

    try {
      await _timelineService.toggleLikeOnComment(
          widget.postId, widget.comment.id, currentUserId);

      if (!mounted) return; // Ensure the widget is still mounted

      setState(() {
        if (isLiked) {
          isLiked = false;
          likesCount--;
        } else {
          isLiked = true;
          likesCount++;
        }
      });
    } catch (e) {
      // Handle any error that may occur during like/unlike operation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error toggling like: $e')),
        );
      }
    }
  }

  Future<UserProfile?> _fetchUserProfile(String userId) async {
    ProfileService profileService = ProfileService();
    return await profileService.getUserProfile(userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: _fetchUserProfile(widget.comment.userId),
      builder: (context, snapshot) {
        UserProfile? user = snapshot.data;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200], // Light gray background
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2), // Shadow position
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Avatar
              GestureDetector(
                onTap: () {
                  // Navigate to user's profile
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        userId: widget.comment.userId,
                        loggedInUserId: currentUserId,
                      ),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFBA8FDB),
                  backgroundImage: user?.profileImageUrl != null
                      ? NetworkImage(user!.profileImageUrl!)
                      : null,
                  child: user?.profileImageUrl == null
                      ? const Icon(Icons.person, color: Colors.white, size: 20)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Comment Content and Actions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username and Timestamp
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Navigate to user's profile
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(
                                  userId: widget.comment.userId,
                                  loggedInUserId: currentUserId,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            user?.name ?? 'No Name',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                        Text(
                          timeago.format(widget.comment.createdAt.toDate()),
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Comment Text
                    Text(
                      widget.comment.content,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                    ),
                    const SizedBox(height: 8),
                    // Like Button and Count - Aligned to Left
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start, // Ensure alignment to left
                      crossAxisAlignment: CrossAxisAlignment.center, // Vertically center the items
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.grey,
                            size: 20,
                          ),
                          onPressed: _toggleLike,
                          padding: EdgeInsets.zero, // Remove default padding
                          constraints: const BoxConstraints(), // Remove default constraints
                        ),
                        const SizedBox(width: 4), // Small space between icon and count
                        Text(
                          '$likesCount',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        // Optional: Add more actions here (e.g., reply, share)
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
