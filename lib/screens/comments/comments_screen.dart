// comments_screen.dart
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
  Widget build(BuildContext context) {
    // Access the LoginProvider to get the currentUserId
    final loginProvider = Provider.of<LoginProvider>(context);
    final String? currentUserId = loginProvider.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Comments"),
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
          : Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Comment>>(
              stream: timelineService.getComments(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading comments: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final comments = snapshot.data!;
                return FutureBuilder<Post>(
                  future: timelineService.getPostById(widget.postId, currentUserId),
                  builder: (context, postSnapshot) {
                    if (postSnapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Error loading post: ${postSnapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    if (postSnapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final post = postSnapshot.data!;

                    // Combine the post and comments into a single list
                    final List<Widget> items = [
                      PostWidget(post: post),
                      const Divider(height: 1),
                    ];
                    items.addAll(comments.map((comment) => CommentWidget(comment: comment)).toList());

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return items[index];
                      },
                    );
                  },
                );
              },
            ),
          ),
          // Input Field to Add Comment
          if (_isSubmitting) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 5,
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
                    _addComment(currentUserId);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
