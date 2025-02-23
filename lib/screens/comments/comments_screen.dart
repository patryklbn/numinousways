import 'package:flutter/material.dart';
import '../../services/timeline_service.dart';
import '../../models/comment.dart';
import '../../services/login_provider.dart';
import 'package:provider/provider.dart';
import '../../widgets/comments/comment_widget.dart';
import '../../models/post.dart';
import '../../models/user_profile.dart';
import '../../services/profile_service.dart';
import '../../widgets/timeline/post_widget.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  final bool showFullPost;

  const CommentsScreen({
    Key? key,
    required this.postId,
    this.showFullPost = false,
  }) : super(key: key);

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TimelineService timelineService = TimelineService();
  final ProfileService profileService = ProfileService();
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> isCommentsScreenOpen = ValueNotifier<bool>(true);
  Post? _post;
  UserProfile? _userProfile;
  bool _loadingUserProfile = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final String? currentUserId = loginProvider.userId;

    if (currentUserId == null) return;

    try {
      final post = await timelineService.getPostById(widget.postId, currentUserId);

      if (mounted) {
        setState(() {
          _post = post;
          _loadingUserProfile = true;
        });
      }

      // Now load the user profile separately
      try {
        final userProfile = await profileService.getUserProfile(post.userId);

        if (mounted) {
          setState(() {
            _userProfile = userProfile;
            _loadingUserProfile = false;
          });
        }
      } catch (e) {
        print('Error loading user profile: $e');
        if (mounted) {
          setState(() {
            _loadingUserProfile = false;
          });
        }
      }

    } catch (e) {
      print('Error loading post: $e');
    }
  }

  void _addComment(String currentUserId) async {
    String content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await timelineService.addComment(widget.postId, content, currentUserId);
      _controller.clear();
      FocusScope.of(context).unfocus();

      // Reload the post to get updated comment count, but keep the user profile
      try {
        final updatedPost = await timelineService.getPostById(widget.postId, currentUserId);
        setState(() {
          _post = updatedPost;
        });
      } catch (e) {
        print('Error refreshing post: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment added successfully!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF6A0DAD),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        ),
      );

      // Scroll to the bottom after adding a comment
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding comment: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Handles the post update from the PostWidget
  void _handlePostUpdate(Post updatedPost) {
    setState(() {
      _post = updatedPost;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    isCommentsScreenOpen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginProvider = Provider.of<LoginProvider>(context);
    final String? currentUserId = loginProvider.userId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
            "Comments",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
            )
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: currentUserId == null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'You must be logged in to view and add comments.',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : _post == null // If post isn't loaded yet
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A0DAD)),
        ),
      )
          : _buildCommentsList(context, currentUserId),
      bottomNavigationBar: currentUserId == null
          ? null
          : Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -2),
              blurRadius: 5,
            ),
          ],
        ),
        child: _isSubmitting
            ? const LinearProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A0DAD)),
          backgroundColor: Colors.white,
        )
            : Padding(
          padding: MediaQuery.of(context).viewInsets.bottom > 0
              ? const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0)
              : const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(24)),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(24)),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                      borderSide: BorderSide(color: Color(0xFF6A0DAD)),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF6A0DAD),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send),
                  color: Colors.white,
                  onPressed: _isSubmitting
                      ? null
                      : () {
                    if (currentUserId != null) {
                      _addComment(currentUserId);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Extracted method to build the comments list with StreamBuilder
  Widget _buildCommentsList(BuildContext context, String? currentUserId) {
    return StreamBuilder<List<Comment>>(
      stream: timelineService.getComments(widget.postId, currentUserId!),
      builder: (context, commentsSnapshot) {
        if (commentsSnapshot.hasError) {
          return Center(
            child: Text(
              'Error loading comments: ${commentsSnapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (commentsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A0DAD)),
            ),
          );
        }
        final comments = commentsSnapshot.data!;

        final List<Widget> combinedList = [
          PostWidget(
            key: ValueKey('post-${_post!.id}'),
            post: _post!,
            isCommentsScreenOpen: isCommentsScreenOpen,
            truncateText: !widget.showFullPost,
            maxLines: widget.showFullPost ? 1000 : 3,
            onPostLikeToggled: _handlePostUpdate,
            userProfile: _userProfile, // Pass the pre-loaded user profile here
          ),
          const Divider(height: 1),
          if (comments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No comments yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Be the first to share your thoughts!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ...comments.map(
                (comment) => CommentWidget(
              key: ValueKey('comment-${comment.id}'),
              postId: widget.postId,
              comment: comment,
            ),
          ),
          // Add extra space at the bottom for the comment box
          const SizedBox(height: 70),
        ];

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: combinedList.length,
          itemBuilder: (context, index) {
            return combinedList[index];
          },
        );
      },
    );
  }
}