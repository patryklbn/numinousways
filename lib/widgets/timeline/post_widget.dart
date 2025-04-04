import 'package:flutter/material.dart';
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
import '../../utils/anonymized_user_helper.dart';
import 'report_content_dialog.dart';

class PostWidget extends StatefulWidget {
  final Post post;
  final ValueNotifier<bool> isCommentsScreenOpen;
  final Function(Post updatedPost)? onPostLikeToggled;
  final bool truncateText;
  final int? maxLines;
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

    // Skip loading user profile if this is an anonymized user
    if (AnonymizedUserHelper.isAnonymizedUser(post.userId)) {
      isUserLoading = false;
    } else if (user == null) {
      _loadUserProfile();
    } else {
      isUserLoading = false;
    }
  }

  @override
  void didUpdateWidget(PostWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.post.id == widget.post.id) {
      post = widget.post;
    } else {
      post = widget.post;
      user = widget.userProfile;

      // Skip loading user profile if this is an anonymized user
      if (AnonymizedUserHelper.isAnonymizedUser(post.userId)) {
        isUserLoading = false;
      } else if (user == null) {
        _loadUserProfile();
      } else {
        isUserLoading = false;
      }
    }

    if (widget.userProfile != null && widget.userProfile != user) {
      user = widget.userProfile;
      isUserLoading = false;
    }
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;

    setState(() {
      isUserLoading = true;
    });

    try {
      ProfileService profileService = ProfileService();
      final fetchedUser = await profileService.getUserProfile(post.userId);

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

  Future<void> _toggleLike(String currentUserId) async {
    if (_isLikeInProgress) return;
    _isLikeInProgress = true;

    final bool wasLiked = post.isLiked;
    final int previousLikesCount = post.likesCount;

    // Optimistic update - only update the like state, keep everything else the same
    setState(() {
      post = post.copyWith(
        isLiked: !wasLiked,
        likesCount: wasLiked ? previousLikesCount - 1 : previousLikesCount + 1,
      );
    });

    // Notify parent of optimistic update
    if (widget.onPostLikeToggled != null) {
      widget.onPostLikeToggled!(post);
    }

    try {
      // Update backend with timeout, but don't replace the post object with the result
      await timelineService.toggleLike(post.id, currentUserId)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      // Revert on error if widget is still mounted
      if (mounted) {
        setState(() {
          post = post.copyWith(
            isLiked: wasLiked,
            likesCount: previousLikesCount,
          );
        });

        // Notify parent of reversion
        if (widget.onPostLikeToggled != null) {
          widget.onPostLikeToggled!(post);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update like. Please try again.'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Reset loading state if widget is still mounted
      if (mounted) {
        setState(() {
          _isLikeInProgress = false;
        });
      }
    }
  }

  void _deletePost(BuildContext context, String postId) async {
    try {
      await timelineService.deletePost(postId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post deleted successfully.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF6A0DAD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting post: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      );
    }
  }

  // New method for reporting posts
  void _showReportDialog(BuildContext context, String postId, String reportedUserId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ReportContentDialog(
          contentId: postId,
          contentType: 'post',
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

  void _navigateToCommentsScreen(BuildContext context, String postId, {bool showFullPost = true}) {
    if (widget.isCommentsScreenOpen.value) return;

    // Set value to true before navigation
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
      // Important: Always reset the flag when returning, regardless of mounted state
      widget.isCommentsScreenOpen.value = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final LoginProvider loginProvider = Provider.of<LoginProvider>(context, listen: false);
    String? currentUserId = loginProvider.userId;

    // Check if text would overflow
    isTextOverflowing = false;
    if (widget.truncateText && post.content.isNotEmpty && widget.maxLines != null) {
      final textSpan = TextSpan(
        text: post.content,
        style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
      );
      final textPainter = TextPainter(
        text: textSpan,
        maxLines: widget.maxLines,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 64);
      isTextOverflowing = textPainter.didExceedMaxLines;
    }

    // Check if the user is anonymized
    final bool isAnonymized = AnonymizedUserHelper.isAnonymizedUser(post.userId);
    final String displayName = isAnonymized
        ? AnonymizedUserHelper.displayName
        : (user?.name ?? 'Loading...');

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: GestureDetector(
              onTap: isAnonymized
                  ? null  // Disable navigation for anonymized users
                  : () {
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
                  : isAnonymized
                  ? AnonymizedUserHelper.getUserAvatar(
                userId: post.userId,
                profileImageUrl: null,
                radius: 28,
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
              onTap: isAnonymized
                  ? null  // Disable navigation for anonymized users
                  : () {
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
                displayName,
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
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (String value) {
                if (value == 'delete' && currentUserId == post.userId) {
                  _deletePost(context, post.id);
                } else if (value == 'report' && currentUserId != null) {
                  _showReportDialog(context, post.id, post.userId);
                }
              },
              itemBuilder: (BuildContext context) => [
                if (currentUserId == post.userId)
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Post'),
                      ],
                    ),
                  ),
                if (currentUserId != null && currentUserId != post.userId)
                  const PopupMenuItem<String>(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.flag, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Report Post'),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Post content and image - always tappable
          // Wrapped in a GestureDetector to make entire area tappable
          GestureDetector(
            onTap: () => _navigateToCommentsScreen(context, post.id, showFullPost: true),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post text content
                if (post.content.isNotEmpty)
                  Padding(
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
                          const Padding(
                            padding: EdgeInsets.only(top: 4.0, bottom: 8.0),
                            child: Text(
                              'Read more',
                              style: TextStyle(
                                color: Color(0xFF6A0DAD),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                // Post image content
                if (post.imageUrl != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: post.imageUrl!,
                        placeholder: (context, url) => Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Center(
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
                  )
                else
                  const SizedBox(height: 8),
              ],
            ),
          ),

          // Like and comment buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: (_isLikeInProgress || currentUserId == null)
                        ? null
                        : () => _toggleLike(currentUserId),
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
                ValueListenableBuilder<bool>(
                  valueListenable: widget.isCommentsScreenOpen,
                  builder: (context, isDisabled, _) {
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isDisabled
                            ? null
                            : () => _navigateToCommentsScreen(context, post.id, showFullPost: true),
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