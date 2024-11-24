// timeline_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/timeline_service.dart';
import '../../models/post.dart';
import '../../services/login_provider.dart';
import '../../widgets/timeline/post_widget.dart';
import 'create_post_screen.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TimelineService timelineService = TimelineService();
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final String currentUserId = loginProvider.userId!; // Ensure userId is not null

    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F7),
      appBar: AppBar(
        title: const Text(
          "Timeline",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Implement refresh functionality if needed
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Post>>(
        stream: timelineService.getPosts(currentUserId), // Pass currentUserId here
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading posts: ${snapshot.error}',
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data!;
          if (posts.isEmpty) {
            return const Center(
              child: Text(
                "No posts available.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              // Implement refresh logic if necessary
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return PostWidget(post: posts[index]);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create post screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        backgroundColor: const Color(0xFF6A0DAD),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
