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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 16.0, top: 8, bottom: 16),
                child: Text(
                  "Add Photo",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library, color: Color(0xFF6A0DAD)),
                ),
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
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_camera, color: Color(0xFF6A0DAD)),
                ),
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
              const SizedBox(height: 16),
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
        SnackBar(
          content: Text('Error uploading image: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
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
        const SnackBar(
          content: Text('Post created successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF6A0DAD),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating post: $e'),
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
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    color: Color(0xFF6A0DAD),
                  ),
                ),
              )
                  : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post Input Box with User Image
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20), // More modern rounded corners
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 8, // Softer shadow
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
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
                                    color: const Color(0xFFBA8FDB),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
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
                                  maxLines: 8,
                                  maxLength: _maxCharacters,
                                  style: const TextStyle(
                                    fontSize: 16, // Slightly larger font
                                  ),
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
                              // Add Image Button with light purple background
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDE7F6), // Light purple background
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextButton.icon(
                                  onPressed: _pickImage,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
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
                              ),
                              // Character Counter
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_maxCharacters - _contentController.text.length} characters left',
                                  style: TextStyle(
                                    color: _contentController.text.length > _maxCharacters * 0.8
                                        ? Colors.orange.shade700 // Changes color when approaching limit
                                        : Colors.grey.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                          Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16), // More rounded corners
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _selectedImage!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _removeImage,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
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
                    // Enhanced Post Button
                    SizedBox(
                      width: double.infinity,
                      height: 56, // Taller button
                      child: ElevatedButton.icon(
                        onPressed: _submitPost,
                        icon: const Icon(Icons.send, size: 22),
                        label: const Text('Post'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A0DAD),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16), // More rounded corners
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5, // Better letter spacing
                          ),
                          elevation: 8, // Increased elevation
                          shadowColor: const Color(0xFF6A0DAD).withOpacity(0.5), // Shadow matching theme color
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