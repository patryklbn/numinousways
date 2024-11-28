// lib/widgets/comment_widget.dart

import 'package:flutter/material.dart';
import '../../models/comment.dart';
import '../../models/user_profile.dart';
import '../../services/profile_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/login_provider.dart';
import 'package:provider/provider.dart';
import '../../screens/profile/profile_screen.dart';

class CommentWidget extends StatelessWidget {
  final Comment comment;

  const CommentWidget({Key? key, required this.comment}) : super(key: key);

  Future<UserProfile?> _fetchUserProfile(String userId) async {
    ProfileService profileService = ProfileService();
    return await profileService.getUserProfile(userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: _fetchUserProfile(comment.userId),
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
                        userId: comment.userId,
                        loggedInUserId: Provider.of<LoginProvider>(context, listen: false).userId!,
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
              // Comment Content
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
                                  userId: comment.userId,
                                  loggedInUserId: Provider.of<LoginProvider>(context, listen: false).userId!,
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
                          timeago.format(comment.createdAt.toDate()),
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Comment Text
                    Text(
                      comment.content,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
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
