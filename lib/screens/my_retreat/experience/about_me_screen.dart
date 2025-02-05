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
    super.dispose();
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        bool requiredField = false,
        int maxLines = 1,
        int? maxLength,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black),
          fillColor: Colors.white,
          filled: true,
          counterText: '', // Hides the default character counter widget
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFB4347F), width: 2),
          ),
        ),
        validator: requiredField
            ? (val) {
          if (val == null || val.trim().isEmpty) {
            return '$label is required';
          }
          return null;
        }
            : null,
      ),
    );
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedPhoto = picked);
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
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
          const SnackBar(content: Text("Profile updated successfully.")),
        );
        Navigator.pop(context, updatedParticipant);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFB4347F);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          "Complete About Me",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold, // Make AppBar text bold
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "We’d love to learn a bit about you. This information will only be visible to fellow participants if you consent.",
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black,
                    fontWeight: FontWeight.bold, // Make this text bold
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  _nameCtrl,
                  "Name (public)",
                  maxLength: 25,
                  requiredField: true,
                ),
                _buildTextField(
                  _aboutYourselfCtrl,
                  "Share a bit about yourself",
                  maxLines: 3,
                  maxLength: 300,
                ),
                _buildTextField(
                  _nicknameCtrl,
                  "Nickname",
                  maxLength: 30,
                ),
                _buildTextField(
                  _pronounsCtrl,
                  "Preferred Pronouns",
                  maxLength: 20,
                ),
                _buildTextField(
                  _workCtrl,
                  "Work or Occupation",
                  maxLines: 2,
                  maxLength: 100,
                ),
                _buildTextField(
                  _hobbiesCtrl,
                  "Hobbies",
                  maxLines: 2,
                  maxLength: 100,
                ),
                _buildTextField(
                  _psychedelicExpCtrl,
                  "Psychedelic Experience",
                  maxLines: 2,
                  maxLength: 200,
                ),
                _buildTextField(
                  _additionalInfoCtrl,
                  "Anything else you want to share?",
                  maxLines: 3,
                  maxLength: 300,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Checkbox(
                      value: _shareBio,
                      activeColor: primaryColor,
                      onChanged: (val) =>
                          setState(() => _shareBio = val ?? false),
                    ),
                    const Expanded(
                      child: Text(
                        "I agree to share my bio with other participants in this retreat.",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Your Photo",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: _selectedPhoto == null
                      ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _pickImage,
                    child: const Text(
                      "Pick Photo",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                      : Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_selectedPhoto!.path),
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _pickImage,
                        child: const Text(
                          "Change Photo",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _submitForm,
                    child: const Text(
                      "Submit",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
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
