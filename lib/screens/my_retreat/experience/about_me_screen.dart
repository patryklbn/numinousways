import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '/../models/experience/participant.dart';
import '/../services/retreat_service.dart';

class AboutMeScreen extends StatefulWidget {
  final String retreatId;
  final Participant participant;

  const AboutMeScreen({
    Key? key,
    required this.retreatId,
    required this.participant,
  }) : super(key: key);

  @override
  _AboutMeScreenState createState() => _AboutMeScreenState();
}

class _AboutMeScreenState extends State<AboutMeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isSubmitting = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _aboutYourselfCtrl;
  late TextEditingController _nicknameCtrl;
  late TextEditingController _pronounsCtrl;
  late TextEditingController _workCtrl;
  late TextEditingController _hobbiesCtrl;
  late TextEditingController _psychedelicExpCtrl;
  late TextEditingController _additionalInfoCtrl;
  late TextEditingController _favoriteAnimalCtrl;
  late TextEditingController _earliestMemoryCtrl;
  late TextEditingController _somethingYouLoveCtrl;
  late TextEditingController _somethingDifficultCtrl;

  bool _shareBio = false;
  XFile? _selectedPhoto;
  final ImagePicker _picker = ImagePicker();

  // Theme colors
  final Color _primaryColor = const Color(0xFF6A0DAD);
  final Color _secondaryColor = const Color(0xFF3700B3);
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    final p = widget.participant;
    _nameCtrl = TextEditingController(text: p.name);
    _aboutYourselfCtrl = TextEditingController(text: p.aboutYourself);
    _nicknameCtrl = TextEditingController(text: p.nickname);
    _pronounsCtrl = TextEditingController(text: p.pronouns);
    _workCtrl = TextEditingController(text: p.work);
    _hobbiesCtrl = TextEditingController(text: p.hobbies);
    _psychedelicExpCtrl = TextEditingController(text: p.psychedelicExperience);
    _additionalInfoCtrl = TextEditingController(text: p.additionalInfo);
    _favoriteAnimalCtrl = TextEditingController(text: p.favoriteAnimal);
    _earliestMemoryCtrl = TextEditingController(text: p.earliestMemory);
    _somethingYouLoveCtrl = TextEditingController(text: p.somethingYouLove);
    _somethingDifficultCtrl = TextEditingController(text: p.somethingDifficult);
    _shareBio = p.shareBio;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _aboutYourselfCtrl.dispose();
    _nicknameCtrl.dispose();
    _pronounsCtrl.dispose();
    _workCtrl.dispose();
    _hobbiesCtrl.dispose();
    _psychedelicExpCtrl.dispose();
    _additionalInfoCtrl.dispose();
    _favoriteAnimalCtrl.dispose();
    _earliestMemoryCtrl.dispose();
    _somethingYouLoveCtrl.dispose();
    _somethingDifficultCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        bool requiredField = false,
        int maxLines = 1,
        int? maxLength,
        IconData? icon,
        String? hintText,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (maxLines > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
              child: Row(
                children: [
                  if (icon != null)
                    Icon(icon, size: 18, color: _primaryColor),
                  if (icon != null)
                    const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: _primaryColor,
                    ),
                  ),
                  if (requiredField)
                    const Text(
                      " *",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            style: TextStyle(
              color: _textColor,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              labelText: maxLines > 1 ? null : label,
              labelStyle: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
              hintText: hintText,
              fillColor: _cardColor,
              filled: true,
              counterText: '', // Hides the default character counter
              prefixIcon: maxLines == 1 && icon != null
                  ? Icon(icon, color: _primaryColor)
                  : null,
              suffixIcon: requiredField && maxLines == 1
                  ? const Icon(Icons.star, color: Colors.red, size: 10)
                  : null,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: maxLines > 1 ? 16 : 14,
              ),
            ),
            validator: requiredField
                ? (val) {
              if (val == null || val.trim().isEmpty) {
                return 'This field is required';
              }
              return null;
            }
                : null,
          ),
          if (maxLength != null && maxLines > 1)
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "${controller.text.length}/$maxLength",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "Choose Photo Source",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.photo_library, color: _primaryColor),
                  title: const Text("Gallery"),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: _primaryColor),
                  title: const Text("Camera"),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (source != null) {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        setState(() => _selectedPhoto = picked);
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      // Show error toast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please fill in all required fields"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    var updatedParticipant = widget.participant.copyWith(
      shareBio: _shareBio,
      name: _nameCtrl.text,
      aboutYourself: _aboutYourselfCtrl.text,
      nickname: _nicknameCtrl.text,
      pronouns: _pronounsCtrl.text,
      work: _workCtrl.text,
      hobbies: _hobbiesCtrl.text,
      psychedelicExperience: _psychedelicExpCtrl.text,
      additionalInfo: _additionalInfoCtrl.text,
      favoriteAnimal: _favoriteAnimalCtrl.text,
      earliestMemory: _earliestMemoryCtrl.text,
      somethingYouLove: _somethingYouLoveCtrl.text,
      somethingDifficult: _somethingDifficultCtrl.text,
    );

    try {
      final retreatService =
      Provider.of<RetreatService>(context, listen: false);

      if (_selectedPhoto != null) {
        final photoUrl = await retreatService.uploadParticipantPhoto(
          widget.retreatId,
          widget.participant.userId,
          File(_selectedPhoto!.path),
        );
        updatedParticipant = updatedParticipant.copyWith(photoUrl: photoUrl);
      }

      await retreatService.addOrUpdateParticipant(
        widget.retreatId,
        updatedParticipant,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Profile updated successfully"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pop(context, updatedParticipant);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          if (icon != null)
            Icon(icon, color: _primaryColor),
          if (icon != null)
            const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo, color: _primaryColor),
              const SizedBox(width: 8),
              Text(
                "Profile Photo",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(75),
                      border: Border.all(
                        color: _primaryColor.withOpacity(0.5),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _selectedPhoto != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(75),
                      child: Image.file(
                        File(_selectedPhoto!.path),
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    )
                        : widget.participant.photoUrl != null && widget.participant.photoUrl!.isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(75),
                      child: Image.network(
                        widget.participant.photoUrl!,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: 80,
                            color: _primaryColor.withOpacity(0.7),
                          );
                        },
                      ),
                    )
                        : Icon(
                      Icons.add_a_photo,
                      size: 50,
                      color: _primaryColor.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(_selectedPhoto != null || (widget.participant.photoUrl != null && widget.participant.photoUrl!.isNotEmpty)
                      ? "Change Photo"
                      : "Select Photo"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Basic Information", icon: Icons.person),
          _buildTextField(
            _nameCtrl,
            "Full Name",
            requiredField: true,
            icon: Icons.badge,
            hintText: "Your preferred full name",
          ),
          _buildTextField(
            _nicknameCtrl,
            "Nickname",
            icon: Icons.face,
            hintText: "What should we call you?",
          ),
          _buildTextField(
            _pronounsCtrl,
            "Preferred Pronouns",
            icon: Icons.people,
            hintText: "e.g., she/her, he/him, they/them",
          ),

          _buildSectionHeader("About You", icon: Icons.info),
          _buildTextField(
            _aboutYourselfCtrl,
            "About Yourself",
            maxLines: 3,
            maxLength: 300,
            icon: Icons.person_outline,
            hintText: "Share a short bio about yourself",
          ),
          _buildTextField(
            _workCtrl,
            "Work or Occupation",
            maxLines: 2,
            maxLength: 100,
            icon: Icons.work,
            hintText: "What do you do professionally?",
          ),
          _buildTextField(
            _hobbiesCtrl,
            "Hobbies and Interests",
            maxLines: 2,
            maxLength: 100,
            icon: Icons.sports_esports,
            hintText: "What do you enjoy doing in your free time?",
          ),

          _buildSectionHeader("Experience", icon: Icons.psychology),
          _buildTextField(
            _psychedelicExpCtrl,
            "Psychedelic Experience",
            maxLines: 2,
            maxLength: 200,
            icon: Icons.auto_awesome,
            hintText: "Share your level of experience if comfortable",
          ),

          _buildSectionHeader("Fun Facts", icon: Icons.emoji_emotions),
          _buildTextField(
            _favoriteAnimalCtrl,
            "Favorite Animal",
            icon: Icons.pets,
            hintText: "What animal do you resonate with?",
          ),
          _buildTextField(
            _earliestMemoryCtrl,
            "Earliest Memory",
            maxLines: 2,
            maxLength: 150,
            icon: Icons.history,
            hintText: "A glimpse of your earliest recollection",
          ),
          _buildTextField(
            _somethingYouLoveCtrl,
            "Something You Love",
            maxLines: 2,
            maxLength: 150,
            icon: Icons.favorite,
            hintText: "Something that brings you joy",
          ),
          _buildTextField(
            _somethingDifficultCtrl,
            "A Challenge You've Overcome",
            maxLines: 2,
            maxLength: 150,
            icon: Icons.trending_up,
            hintText: "A difficult experience that helped you grow",
          ),

          _buildSectionHeader("Additional Information", icon: Icons.add_comment),
          _buildTextField(
            _additionalInfoCtrl,
            "Anything Else?",
            maxLines: 3,
            maxLength: 300,
            icon: Icons.more_horiz,
            hintText: "Any other information you want to share with the group",
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.privacy_tip, color: Colors.blue[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Privacy Settings",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _shareBio,
                              activeColor: _primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (val) => setState(() => _shareBio = val ?? false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              "I agree to share my bio with other participants in this retreat.",
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryColor, _secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "About Me",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: "Why this information?",
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    "Why We Ask",
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: const Text(
                    "Sharing information about yourself helps create connection with your fellow retreat participants. It also helps our facilitators better understand the group. You control what you share and who sees it.",
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: _primaryColor,
                      ),
                      child: const Text("Got it"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Introduction card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.group, color: _primaryColor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "We'd love to learn about you. This information helps build community among participants and gives our facilitators insights to better support your journey.",
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: _textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Photo section
                _buildPhotoSection(),

                const SizedBox(height: 24),

                // Form fields
                _buildFormSection(),

                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: _primaryColor,
                      elevation: 5,
                      shadowColor: _primaryColor.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _submitForm,
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle),
                        SizedBox(width: 8),
                        Text(
                          "SAVE PROFILE",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}