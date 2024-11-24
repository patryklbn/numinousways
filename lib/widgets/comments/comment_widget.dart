import 'package:flutter/material.dart';
import '../../models/comment.dart';
import '../../models/user_profile.dart';
import '../../services/profile_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/login_provider.dart';
import 'package:provider/provider.dart';
import '../../screens/profile/profile_screen.dart'; // Import ProfileScreen

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
        return ListTile(
          leading: GestureDetector(
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
              backgroundColor: const Color(0xFFBA8FDB),
              backgroundImage: user?.profileImageUrl != null
                  ? NetworkImage(user!.profileImageUrl!)
                  : null,
              child: user?.profileImageUrl == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
          ),
          title: GestureDetector(
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
                fontSize: 16,
                color: Color(0xFF333333),
              ),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.content,
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
              ),
              const SizedBox(height: 4),
              Text(
                timeago.format(comment.createdAt.toDate()),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        );
      },
    );
  }
}
