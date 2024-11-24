// comments_screen.dart
import 'package:flutter/material.dart';
import '../../services/timeline_service.dart';
import '../../models/comment.dart';
import '../../services/login_provider.dart';
import 'package:provider/provider.dart';
import '../../widgets/comments/comment_widget.dart';

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

  void _addComment() async {
    String content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final String currentUserId = loginProvider.userId!; // Ensure userId is not null

    try {
      await timelineService.addComment(widget.postId, content, currentUserId);
      _controller.clear();
      FocusScope.of(context).unfocus();
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
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Comment>>(
                stream: timelineService.getComments(widget.postId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading comments: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final comments = snapshot.data!;
                  if (comments.isEmpty) {
                    return const Center(child: Text("No comments yet."));
                  }
                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      return CommentWidget(comment: comments[index]);
                    },
                  );
                },
              ),
            ),
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
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _isSubmitting ? null : _addComment,
                  ),
                ],
              ),
            ),
          ],
        ));
  }
}
