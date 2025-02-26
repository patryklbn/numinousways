import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/timeline_service.dart';
import '../../models/post.dart';
import '../../services/login_provider.dart';
import '../../widgets/timeline/post_widget.dart';
import '../../widgets/app_drawer.dart';
import 'create_post_screen.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({Key? key}) : super(key: key);

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final ValueNotifier<bool> isCommentsScreenOpen = ValueNotifier<bool>(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    isCommentsScreenOpen.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshPosts() async {
    // Add a small delay to make the refresh animation more visible
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final TimelineService timelineService = TimelineService();
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final String currentUserId = loginProvider.userId!;

    return Scaffold(
      backgroundColor: Colors.white, // Changed to white background for cleaner look with dividers
      appBar: AppBar(
        title: const Text(
          "Timeline",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
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
          // Add refresh button in app bar
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshPosts,
            tooltip: 'Refresh timeline',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: StreamBuilder<List<Post>>(
        stream: timelineService.getPosts(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading posts: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A0DAD),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A0DAD)),
              ),
            );
          }

          final posts = snapshot.data!;

          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "No posts available yet",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6A0DAD),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Be the first to share something!",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreatePostScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Post'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A0DAD),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshPosts,
            color: const Color(0xFF6A0DAD),
            backgroundColor: Colors.white,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 80), // Extra bottom padding for FAB
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return PostWidget(
                  post: posts[index],
                  isCommentsScreenOpen: isCommentsScreenOpen,
                  truncateText: true, // Enable text truncation
                  maxLines: 5, // Limit to 3 lines before truncating
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6A0DAD), Color(0xFF3700B3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            // Navigate to create post screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreatePostScreen()),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add,
            size: 28,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}