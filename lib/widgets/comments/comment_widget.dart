import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/comment.dart';
import '../../models/user_profile.dart';
import '../../services/profile_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/login_provider.dart';
import 'package:provider/provider.dart';
import '../../services/timeline_service.dart';
import '../../screens/profile/profile_screen.dart';
import '../../utils/anonymized_user_helper.dart';
import './/widgets/timeline/report_content_dialog.dart'; // Import the report dialog

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
  UserProfile? user;
  bool isUserLoading = true;

  @override
  void initState() {
    super.initState();
    isLiked = widget.comment.isLiked;
    likesCount = widget.comment.likesCount;

    // Initialize currentUserId in initState
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    currentUserId = loginProvider.userId ?? '';

    // Check if the user is anonymized
    if (AnonymizedUserHelper.isAnonymizedUser(widget.comment.userId)) {
      isUserLoading = false;
    } else {
      _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;

    setState(() {
      isUserLoading = true;
    });

    try {
      ProfileService profileService = ProfileService();
      final fetchedUser = await profileService.getUserProfile(widget.comment.userId);

      if (!mounted) return;

      setState(() {
        user = fetchedUser;
        isUserLoading = false;
      });
    } catch (e) {
      print('Error loading user profile: $e');
      if (mounted) {
        setState(() {
          isUserLoading = false;
        });
      }
    }
  }

  void _toggleLike() async {
    if (currentUserId.isEmpty) return;

    try {
      // Toggle like on the comment in Firestore
      await _timelineService.toggleLikeOnComment(
        widget.postId,
        widget.comment.id,
        currentUserId,
      );

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error toggling like: $e')),
        );
      }
    }
  }

  Future<void> _deleteComment() async {
    try {
      await _timelineService.deleteComment(widget.postId, widget.comment.id);
      // Because you have a real-time subscription to comments in CommentsScreen,
      // the list should auto-update upon deletion. If not, you can manually refresh.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment deleted'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting comment: $e')),
        );
      }
    }
  }

  void _showReportDialog(BuildContext context, String commentId, String reportedUserId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ReportContentDialog(
          contentId: commentId,
          contentType: 'comment',
          reportedUserId: reportedUserId,
        );
      },
    ).then((reported) {
      if (reported == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your report. We\'ll review this content.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF6A0DAD),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        );
      }
    });
  }

  void _showCommentOptions() {
    if (currentUserId.isEmpty) return;

    // Show different options based on whether the user is the comment owner or not
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Delete option (only for the comment owner)
                if (widget.comment.userId == currentUserId)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Delete Comment'),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmDelete();
                    },
                  ),

                // Report option (only for users who aren't the comment owner)
                if (widget.comment.userId != currentUserId)
                  ListTile(
                    leading: const Icon(Icons.flag, color: Colors.orange),
                    title: const Text('Report Comment'),
                    onTap: () {
                      Navigator.pop(context);
                      _showReportDialog(context, widget.comment.id, widget.comment.userId);
                    },
                  ),

                // Cancel option
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if the user is anonymized
    final bool isAnonymized = AnonymizedUserHelper.isAnonymizedUser(widget.comment.userId);
    final String displayName = isAnonymized
        ? AnonymizedUserHelper.displayName
        : (user?.name ?? 'Deleted User');

    return GestureDetector(
      onLongPress: () => _showCommentOptions(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Avatar
            GestureDetector(
              onTap: isAnonymized
                  ? null  // Disable navigation for anonymized users
                  : () {
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
              child: isUserLoading
                  ? const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFF4DB6AC),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
                  : isAnonymized
                  ? AnonymizedUserHelper.getUserAvatar(
                userId: widget.comment.userId,
                profileImageUrl: null,
                radius: 24,
              )
                  : CircleAvatar(
                radius: 24, // Outer circle
                backgroundColor: const Color(0xFF4DB6AC),
                child: CircleAvatar(
                  radius: 22, // Inner circle with the actual image
                  backgroundImage: (user != null && user!.profileImageUrl != null)
                      ? NetworkImage(user!.profileImageUrl!)
                      : null,
                  child: (user == null || user!.profileImageUrl == null)
                      ? const Icon(Icons.person, color: Colors.white, size: 24)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Comment Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username, Timestamp and More Options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: isAnonymized
                            ? null  // Disable navigation for anonymized users
                            : () {
                          // Navigate to user profile
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
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            timeago.format(widget.comment.createdAt.toDate()),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          // More options button
                          if (currentUserId.isNotEmpty)
                            InkWell(
                              onTap: _showCommentOptions,
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(
                                  Icons.more_vert,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Comment text (if any)
                  if (widget.comment.content.isNotEmpty)
                    Text(
                      widget.comment.content,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                    ),

                  // Comment image (if any)
                  if (widget.comment.imageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: GestureDetector(
                        onTap: () => _showFullScreenImage(context, widget.comment.imageUrl!),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: widget.comment.imageUrl!,
                            placeholder: (context, url) => Container(
                              height: 150,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A0DAD)),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 150,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Like button
                  GestureDetector(
                    onTap: _toggleLike,
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$likesCount',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Prompt for confirmation before deleting
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _deleteComment(); // Actually delete the comment
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.error,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}