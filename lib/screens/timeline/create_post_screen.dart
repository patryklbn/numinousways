// create_post_screen.dart
import 'package:flutter/material.dart';
import '../../services/timeline_service.dart';
import 'package:provider/provider.dart';
import '../../services/login_provider.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  String _content = '';
  String? _imageUrl; // Placeholder for image uploads

  bool _isSubmitting = false;

  void _submitPost() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isSubmitting = true;
    });

    TimelineService timelineService = TimelineService();
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final String currentUserId = loginProvider.userId!; // Ensure userId is not null

    try {
      await timelineService.createPost(
        _content,
        imageUrl: _imageUrl,
        currentUserId: currentUserId, // Pass currentUserId here
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Placeholder for image upload functionality
  // You can integrate image_picker and Firebase Storage here

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Create Post",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        flexibleSpace: Container( // Wrap BoxDecoration in a Container
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isSubmitting
            ? const Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: Column(
            children: [
              // Post Content Field
              TextFormField(
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'What\'s on your mind?',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Post content cannot be empty';
                  }
                  return null;
                },
                onSaved: (value) {
                  _content = value!.trim();
                },
              ),
              const SizedBox(height: 20),
              // Image Upload Button (Placeholder)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image, color: Color(0xFF6A0DAD)),
                    onPressed: () {
                      // Implement image picker functionality
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Add Image',
                    style: TextStyle(
                      color: Color(0xFF6A0DAD),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Post Button
              ElevatedButton.icon(
                onPressed: _submitPost,
                icon: const Icon(Icons.send),
                label: const Text('Post'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A0DAD), // Use 'backgroundColor'
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
