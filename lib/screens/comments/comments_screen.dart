import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  File? _selectedCommentImage;
  final ImagePicker _imagePicker = ImagePicker();

  // Use a ValueNotifier for character count to prevent rebuilding the entire screen
  final ValueNotifier<int> _characterCount = ValueNotifier<int>(0);

  // Cache for comments to prevent flickering
  List<Comment>? _cachedComments;
  bool _isCommentsLoading = true;
  String? _commentsError;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Update character count without triggering setState
    _controller.addListener(() {
      _characterCount.value = _controller.text.length;
    });

    // Load comments once
    _loadComments();
  }

  Future<void> _loadComments() async {
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final String? currentUserId = loginProvider.userId;

    if (currentUserId == null) return;

    setState(() {
      _isCommentsLoading = true;
      _commentsError = null;
    });

    try {
      // Subscribe to the stream but manage state manually
      timelineService.getComments(widget.postId, currentUserId).listen(
              (comments) {
            if (mounted) {
              setState(() {
                _cachedComments = comments;
                _isCommentsLoading = false;
              });
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _commentsError = 'Error loading comments: $error';
                _isCommentsLoading = false;
              });
            }
          }
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _commentsError = 'Error loading comments: $e';
          _isCommentsLoading = false;
        });
      }
    }
  }

  Future<void> _loadData() async {
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final String? currentUserId = loginProvider.userId;

    if (currentUserId == null) return;

    // Don't reload if we already have data
    if (_post != null && _userProfile != null) return;

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

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Compress images to reduce storage usage
    );

    if (pickedFile != null && mounted) {
      setState(() {
        _selectedCommentImage = File(pickedFile.path);
      });
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedCommentImage = null;
    });
  }

  void _addComment(String currentUserId) async {
    String content = _controller.text.trim();

    // Check for empty content (if no image) and length limit
    if ((content.isEmpty && _selectedCommentImage == null) || content.length > 250) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? imageUrl;

      // Upload image if selected
      if (_selectedCommentImage != null) {
        imageUrl = await timelineService.uploadCommentImage(_selectedCommentImage!, widget.postId);
      }

      // Add comment with possible image
      await timelineService.addComment(
          widget.postId,
          content,
          currentUserId,
          imageUrl: imageUrl
      );

      _controller.clear();
      setState(() {
        _selectedCommentImage = null; // Clear selected image
      });
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
    // Only update the like status, not the entire post
    setState(() {
      if (_post != null) {
        _post = _post!.copyWith(
            isLiked: updatedPost.isLiked,
            likesCount: updatedPost.likesCount
        );
      }
    });
  }

  // Method to dismiss keyboard
  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _controller.removeListener(() {});
    _controller.dispose();
    _scrollController.dispose();
    isCommentsScreenOpen.dispose();
    _characterCount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final String? currentUserId = loginProvider.userId;

    return GestureDetector(
      // Add tap anywhere to dismiss keyboard
      onTap: _dismissKeyboard,
      // Add horizontal swipe detection for going back
      onHorizontalDragEnd: (details) {
        // If the swipe is from left to right with sufficient velocity
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          // Check if we can pop this route
          if (Navigator.of(context).canPop()) {
            // Make sure to reset the comments screen flag
            isCommentsScreenOpen.value = false;
            // Pop the route to go back
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true, // This helps with keyboard resizing
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true, // Added this line to center the title
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
            : GestureDetector(
          // Add another gesture detector for the content area
          // This ensures tapping on the list also dismisses keyboard
          onTap: _dismissKeyboard,
          child: _buildCommentsList(context, currentUserId),
        ),
        bottomNavigationBar: currentUserId == null
            ? null
            : Padding(
          // Add padding to respect keyboard height
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Show selected image preview if any - now with larger size
                if (_selectedCommentImage != null)
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedCommentImage!,
                            height: 180, // Increased from 100 to 180
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        GestureDetector(
                          onTap: _removeSelectedImage,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.close, size: 20, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Progress indicator or input row
                _isSubmitting
                    ? const LinearProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A0DAD)),
                  backgroundColor: Colors.white,
                )
                    : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Character counter at the top with ValueListenableBuilder
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0, right: 8.0),
                        child: ValueListenableBuilder<int>(
                          valueListenable: _characterCount,
                          builder: (context, count, _) {
                            return Text(
                              "$count/250",
                              style: TextStyle(
                                fontSize: 12,
                                color: count > 230 ? Colors.red : Colors.grey.shade600,
                              ),
                            );
                          },
                        ),
                      ),
                      Row(
                        children: [
                          // Image picker button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.image_outlined),
                              color: const Color(0xFF6A0DAD),
                              onPressed: _pickImage,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Comment text field
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              maxLength: 250,
                              textAlignVertical: TextAlignVertical.center, // Add this to center text vertically
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5, // Add this to improve text positioning
                              ),
                              buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                                // Don't show the counter here, we're displaying it above
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: 'Add a comment...',
                                hintStyle: TextStyle(color: Colors.grey.shade500),
                                // Updated padding to ensure consistent centering on Android
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                isDense: true, // Add this to make input more compact
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
                                // Add a clear button inside the text field
                                suffixIcon: _controller.text.isNotEmpty
                                    ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  color: Colors.grey.shade400,
                                  onPressed: () {
                                    _controller.clear();
                                    _dismissKeyboard();
                                  },
                                )
                                    : null,
                              ),
                              minLines: 1,
                              maxLines: 3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Send button with GestureDetector
                          ValueListenableBuilder<int>(
                            valueListenable: _characterCount,
                            builder: (context, count, _) {
                              final bool isTextEmpty = count == 0;
                              final bool isDisabled = _isSubmitting || (isTextEmpty && _selectedCommentImage == null);

                              return GestureDetector(
                                onTap: isDisabled
                                    ? null
                                    : () {
                                  if (currentUserId != null) {
                                    _addComment(currentUserId);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDisabled
                                        ? const Color(0xFF6A0DAD).withOpacity(0.4) // Lighter purple when disabled
                                        : const Color(0xFF6A0DAD),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.send,
                                    color: Colors.white, // Always white
                                    size: 24,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Add this method to the _CommentsScreenState class
  void updatePostData(Post updatedPost) {
    if (mounted) {
      setState(() {
        _post = updatedPost;
      });
    }
  }

  Widget _buildCommentsList(BuildContext context, String? currentUserId) {
    // If comments are still loading, show loading indicator
    if (_isCommentsLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A0DAD)),
        ),
      );
    }

    // If there was an error loading comments
    if (_commentsError != null) {
      return Center(
        child: Text(
          _commentsError!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    // Use cached comments
    final comments = _cachedComments ?? [];

    // Use a ListView.builder for the entire content including the post
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 100), // Extra padding at bottom for comment box
      itemCount: comments.isEmpty ? 2 : comments.length + 2, // +1 for post, +1 for empty state or bottom padding
      itemBuilder: (context, index) {
        if (index == 0) {
          // First item is always the post
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PostWidget(
                key: ValueKey('post-${_post!.id}'),
                post: _post!,
                isCommentsScreenOpen: isCommentsScreenOpen,
                truncateText: !widget.showFullPost,
                maxLines: widget.showFullPost ? 1000 : 3,
                onPostLikeToggled: _handlePostUpdate,
                userProfile: _userProfile,
              ),

            ],
          );
        } else if (comments.isEmpty && index == 1) {
          // Empty state when no comments
          return Padding(
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
          );
        } else if (index == comments.length + 1) {
          // Last item is bottom padding
          return const SizedBox(height: 70);
        } else {
          // Comment items
          return CommentWidget(
            key: ValueKey('comment-${comments[index - 1].id}'),
            postId: widget.postId,
            comment: comments[index - 1],
          );
        }
      },
    );
  }
}