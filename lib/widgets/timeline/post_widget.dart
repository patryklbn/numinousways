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

class PostWidget extends StatefulWidget {
  final Post post;
  final ValueNotifier<bool> isCommentsScreenOpen;
  final Function(Post updatedPost)? onPostLikeToggled;
  final bool truncateText;
  final int? maxLines;
  // Add a user profile parameter to avoid refetching
  final UserProfile? userProfile;

  const PostWidget({
    Key? key,
    required this.post,
    required this.isCommentsScreenOpen,
    this.onPostLikeToggled,
    this.truncateText = true,
    this.maxLines = 3,
    this.userProfile,
  }) : super(key: key);

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  late Post post;
  late bool isTextOverflowing;
  final TimelineService timelineService = TimelineService();
  UserProfile? user;
  bool isUserLoading = true;
  bool _isLikeInProgress = false;

  @override
  void initState() {
    super.initState();
    post = widget.post;
    user = widget.userProfile;

    if (user == null) {
      _loadUserProfile();
    } else {
      isUserLoading = false;
    }
  }

  @override
  void didUpdateWidget(PostWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only update post data without touching user profile
    if (oldWidget.post.id == widget.post.id) {
      post = widget.post;
    }
    // If post ID changed, it's a completely different post
    else {
      post = widget.post;
      user = widget.userProfile;

      if (user == null) {
        _loadUserProfile();
      } else {
        isUserLoading = false;
      }
    }

    // If we received a new user profile from parent
    if (widget.userProfile != null && widget.userProfile != user) {
      user = widget.userProfile;
      isUserLoading = false;
    }
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      isUserLoading = true;
    });

    try {
      ProfileService profileService = ProfileService();
      user = await profileService.getUserProfile(post.userId);
    } catch (e) {
      print('Error loading user profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          isUserLoading = false;
        });
      }
    }
  }

  void _deletePost(BuildContext context, String postId) async {
    try {
      await timelineService.deletePost(postId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post deleted successfully.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF6A0DAD),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting post: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        ),
      );
    }
  }

  void _navigateToCommentsScreen(BuildContext context, String postId, {bool showFullPost = false}) {
    if (widget.isCommentsScreenOpen.value) return; // Prevent multiple navigation

    widget.isCommentsScreenOpen.value = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsScreen(
          postId: postId,
          showFullPost: showFullPost,
        ),
      ),
    ).then((_) {
      widget.isCommentsScreenOpen.value = false;
    });
  }

  void _toggleLike(String currentUserId) async {
    // Avoid multiple like operations at once
    if (_isLikeInProgress) return;
    _isLikeInProgress = true;

    // Immediately update UI
    setState(() {
      post = post.copyWith(
        isLiked: !post.isLiked,
        likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
      );
    });

    // Notify parent if needed
    if (widget.onPostLikeToggled != null) {
      widget.onPostLikeToggled!(post);
    }

    try {
      // Update backend
      await timelineService.toggleLike(post.id, currentUserId);
    } catch (e) {
      // Revert UI on error
      setState(() {
        post = post.copyWith(
          isLiked: !post.isLiked,
          likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
        );
      });

      // Notify parent about the reversion
      if (widget.onPostLikeToggled != null) {
        widget.onPostLikeToggled!(post);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating like: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _isLikeInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final LoginProvider loginProvider = Provider.of<LoginProvider>(context, listen: false);
    String? currentUserId = loginProvider.userId;

    // Check if text would overflow
    isTextOverflowing = false;
    if (widget.truncateText && post.content.isNotEmpty && widget.maxLines != null) {
      // Create a text painter to measure if text would overflow
      final textSpan = TextSpan(
        text: post.content,
        style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
      );
      final textPainter = TextPainter(
        text: textSpan,
        maxLines: widget.maxLines,
        textDirection: TextDirection.ltr,
      );

      // Layout with width constraint of screen minus padding
      textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 64);

      // Check if text exceeds maxLines
      isTextOverflowing = textPainter.didExceedMaxLines;
    }

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: GestureDetector(
              onTap: () {
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
              child: isUserLoading
                  ? const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFFBA8FDB),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
                  : CircleAvatar(
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
            trailing: currentUserId == post.userId
                ? PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (String value) {
                if (value == 'delete') {
                  _deletePost(context, post.id);
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text('Delete Post'),
                      ],
                    ),
                  ),
                ];
              },
            )
                : null,
          ),
          if (post.content.isNotEmpty)
            GestureDetector(
              onTap: isTextOverflowing ? () => _navigateToCommentsScreen(context, post.id, showFullPost: true) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.content,
                      style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
                      maxLines: widget.truncateText ? widget.maxLines : null,
                      overflow: widget.truncateText ? TextOverflow.ellipsis : TextOverflow.visible,
                    ),
                    if (isTextOverflowing)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                        child: Text(
                          'Read more',
                          style: TextStyle(
                            color: const Color(0xFF6A0DAD),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (post.imageUrl != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () => _navigateToCommentsScreen(context, post.id),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrl!,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A0DAD)),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.broken_image)),
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            child: Row(
              children: [
                // Like button with enhanced styling
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: (_isLikeInProgress || currentUserId == null) ? null : () => _toggleLike(currentUserId),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: post.isLiked ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          _isLikeInProgress
                              ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                post.isLiked ? Colors.red : Colors.grey,
                              ),
                            ),
                          )
                              : Icon(
                            post.isLiked ? Icons.favorite : Icons.favorite_border,
                            color: post.isLiked ? Colors.red : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.likesCount}',
                            style: TextStyle(
                              color: post.isLiked ? Colors.red : Colors.grey,
                              fontWeight: post.isLiked ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Comment button with enhanced styling
                ValueListenableBuilder<bool>(
                  valueListenable: widget.isCommentsScreenOpen,
                  builder: (context, isDisabled, _) {
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isDisabled
                            ? null
                            : () => _navigateToCommentsScreen(context, post.id),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
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
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Divider at the bottom of each post instead of Card elevation
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.withOpacity(0.2),
          ),
        ],
      ),
    );
  }
}