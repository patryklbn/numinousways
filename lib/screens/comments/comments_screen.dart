import 'package:flutter/material.dart';
import '../../services/timeline_service.dart';
import '../../models/comment.dart';
import '../../services/login_provider.dart';
import 'package:provider/provider.dart';
import '../../widgets/comments/comment_widget.dart';
import '../../models/post.dart';
import '../../widgets/timeline/post_widget.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;

  const CommentsScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TimelineService timelineService = TimelineService();
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> isCommentsScreenOpen = ValueNotifier<bool>(true); // Default to true since the screen is already open

  // Method to add a comment
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment added successfully!')),
      );

      // Scroll to the bottom to show the new comment
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding comment: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose(); // Dispose the ScrollController
    isCommentsScreenOpen.dispose(); // Dispose ValueNotifier
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access the LoginProvider to get the currentUserId
    final loginProvider = Provider.of<LoginProvider>(context);
    final String? currentUserId = loginProvider.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Comments",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
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
          : FutureBuilder<Post>(
        future: timelineService.getPostById(widget.postId, currentUserId),
        builder: (context, postSnapshot) {
          if (postSnapshot.hasError) {
            return Center(
              child: Text(
                'Error loading post: ${postSnapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (postSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final post = postSnapshot.data!;

          return StreamBuilder<List<Comment>>(
            stream: timelineService.getComments(widget.postId, currentUserId),
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
                return const Center(child: CircularProgressIndicator());
              }
              final comments = commentsSnapshot.data!;

              // Create a combined list with PostWidget and comments
              final List<Widget> combinedList = [
                PostWidget(
                  key: ValueKey(post.id),
                  post: post,
                  isCommentsScreenOpen: isCommentsScreenOpen, // Pass ValueNotifier here
                ),
                const Divider(height: 1),
                ...comments.map(
                      (comment) => CommentWidget(
                    key: ValueKey(comment.id),
                    postId: widget.postId,
                    comment: comment,
                  ),
                ),
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
        },
      ),
      bottomNavigationBar: _isSubmitting
          ? const LinearProgressIndicator()
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Add a comment...',
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                  ),
                ),
                minLines: 1,
                maxLines: 3,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              color: _isSubmitting
                  ? Colors.grey
                  : const Color(0xFF6A0DAD), // Match theme color
              onPressed: _isSubmitting
                  ? null
                  : () {
                if (currentUserId != null) {
                  _addComment(currentUserId);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
