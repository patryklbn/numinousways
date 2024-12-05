// create_post_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../services/timeline_service.dart';
import 'package:provider/provider.dart';
import '../../services/login_provider.dart';
import '../../models/user_profile.dart';
import '../../services/profile_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  String _content = '';
  File? _selectedImage;
  final _contentController = TextEditingController();

  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();
  final int _maxCharacters = 280;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_updateCharacterCount);
  }

  void _updateCharacterCount() {
    setState(() {}); // This will rebuild the widget to show the updated character count
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () async {
                  final XFile? file = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 800,
                    maxHeight: 800,
                  );
                  Navigator.of(context).pop(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  final XFile? file = await _picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 800,
                    maxHeight: 800,
                  );
                  Navigator.of(context).pop(file);
                },
              ),
            ],
          ),
        );
      },
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<String?> _uploadImage(File image) async {
    try {
      String fileName = 'posts/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(image);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    }
  }

  void _submitPost() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isSubmitting = true;
    });

    TimelineService timelineService = TimelineService();
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final String currentUserId = loginProvider.userId!;

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
        if (imageUrl == null) {
          setState(() {
            _isSubmitting = false;
          });
          return;
        }
      }

      await timelineService.createPost(
        _content,
        imageUrl: imageUrl,
        currentUserId: currentUserId,
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

  @override
  Widget build(BuildContext context) {
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final String currentUserId = loginProvider.userId!;

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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: FutureBuilder<UserProfile?>(
          future: ProfileService().getUserProfile(currentUserId),
          builder: (context, snapshot) {
            UserProfile? user = snapshot.data;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post Input Box with User Image
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20), // Increase padding for a larger box
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User Profile Picture with Circle Border
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFBA8FDB), // Same color as in PostWidget
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: const Color(0xFFBA8FDB),
                                  backgroundImage: user?.profileImageUrl != null
                                      ? NetworkImage(user!.profileImageUrl!)
                                      : null,
                                  child: user?.profileImageUrl == null
                                      ? const Icon(Icons.person, color: Colors.white, size: 24)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Post Input Field
                              Expanded(
                                child: TextFormField(
                                  controller: _contentController,
                                  maxLines: 8, // Increased to make the box bigger
                                  maxLength: _maxCharacters,
                                  decoration: const InputDecoration(
                                    hintText: 'What\'s on your mind?',
                                    border: InputBorder.none,
                                    alignLabelWithHint: true,
                                    counterText: "",
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
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Character Counter and Add Image Button in the same row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Add Image Button
                              TextButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(
                                  Icons.image,
                                  color: Color(0xFF6A0DAD),
                                ),
                                label: const Text(
                                  'Add Image',
                                  style: TextStyle(
                                    color: Color(0xFF6A0DAD),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              // Character Counter
                              Text(
                                '${_maxCharacters - _contentController.text.length} characters left',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Display Selected Image
                    if (_selectedImage != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _removeImage,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 30),
                    // Post Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitPost,
                        icon: const Icon(Icons.send),
                        label: const Text('Post'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A0DAD),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          elevation: 5,
                          shadowColor: Colors.grey.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
