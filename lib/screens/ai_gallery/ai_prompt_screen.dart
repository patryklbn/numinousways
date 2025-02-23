import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../services/login_provider.dart';
import '../../services/ai_gallery_service.dart';

class AiPromptScreen extends StatefulWidget {
  const AiPromptScreen({Key? key}) : super(key: key);

  @override
  State<AiPromptScreen> createState() => _AiPromptScreenState();
}

class _AiPromptScreenState extends State<AiPromptScreen> {
  final TextEditingController _promptController = TextEditingController();

  bool _isGenerating = false;
  bool _hasGeneratedImage = false;
  bool _showFilters = false;
  String _previewText = '';
  String? _generatedImageUrl;
  Map<String, String>? _imageUrls; // Store all URL versions
  String? _errorMessage;
  String? _selectedFilter;
  String? _appliedFilter; // Track which filter was actually applied to the generated image

  // List of potentially problematic words for basic content moderation
  final List<String> _moderationWords = [
    'nude', 'naked', 'pornography', 'pornographic', 'explicit',
    'violence', 'gore', 'bloody', 'weapon', 'gun', 'suicide',
    'terrorist', 'terrorism', 'bomb', 'sexual', 'drugs', 'inappropriate'
  ];

  @override
  void initState() {
    super.initState();
    _promptController.addListener(() {
      setState(() {
        _previewText = _promptController.text;
      });
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final userId = loginProvider.userId;

    // Fetch actual user name instead of using placeholder
    String userName = 'User'; // Default fallback
    if (userId != null) {
      // Start with the fetch, but don't wait for it in build
      _fetchUserName(userId).then((name) {
        if (mounted && name != null && name != userName) {
          setState(() {
            userName = name;
          });
        }
      });
    }

    final aiGalleryService = AiGalleryService();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'AI Image Generator',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
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
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Either show AI Assistant header or filters
              if (!_showFilters)
                _buildAiAssistantHeader()
              else
                _buildFiltersSection(),

              const SizedBox(height: 16),
              _buildPromptInput(),
              const SizedBox(height: 20),

              // Generate button or loading indicator
              if (!_hasGeneratedImage) _buildGenerateButton(context, userId, aiGalleryService),

              // Error message if any
              if (_errorMessage != null && !_hasGeneratedImage) _buildErrorMessage(),

              // Preview image after generation
              if (_hasGeneratedImage && _generatedImageUrl != null) ...[
                _buildImagePreview(),
                const SizedBox(height: 20),
                _buildPublishButton(context, userId, userName, aiGalleryService),
                const SizedBox(height: 20),
                _buildRegenerateButton(context, userId, aiGalleryService),
              ],

              const SizedBox(height: 24),
              _buildTipsSection(),
            ],
          ),
        ),
      ),
    );
  }

  // Fetch the actual user's name from Firestore
  Future<String?> _fetchUserName(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['name'] != null) {
          return data['name'] as String;
        }
      }
      return null;
    } catch (e) {
      log('Error fetching user name: $e');
      return null;
    }
  }

  Widget _buildAiAssistantHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2A3E), Color(0xFF1A1A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6A0DAD), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6A0DAD).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const FaIcon(
              FontAwesomeIcons.wandSparkles,
              color: Color(0xFF6A0DAD),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "Create amazing AI-generated images! Click the filter icon in the top right to choose artistic styles for your creation.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose a Style Filter',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        _buildFilterCard(
          title: 'Mystic Glow',
          description: 'Soft, ethereal energy with gentle light effects. Perfect for capturing profound experiences.',
          icon: FontAwesomeIcons.moon,
          color: Colors.purple,
          isSelected: _selectedFilter == 'Mystic Glow',
        ),
        const SizedBox(height: 8),
        _buildFilterCard(
          title: 'Nature Vibes',
          description: 'Harmonious natural elements enhanced with grounding earthy tones. Ideal for connection moments.',
          icon: FontAwesomeIcons.leaf,
          color: Colors.green,
          isSelected: _selectedFilter == 'Nature Vibes',
        ),
        const SizedBox(height: 8),
        _buildFilterCard(
          title: 'Psychedelic Burst',
          description: 'Subtle color enhancement with light visionary elements. Captures the essence of transformative journeys.',
          icon: FontAwesomeIcons.palette,
          color: Colors.orange,
          isSelected: _selectedFilter == 'Psychedelic Burst',
        ),
        const SizedBox(height: 8),
        _buildFilterCard(
          title: 'Zen Serenity',
          description: 'Peaceful, balanced composition with a meditative quality. Reflects integration and mindfulness.',
          icon: FontAwesomeIcons.spa,
          color: Colors.teal,
          isSelected: _selectedFilter == 'Zen Serenity',
        ),
      ],
    );
  }

  Widget _buildFilterCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedFilter = null;
          } else {
            _selectedFilter = title;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF6A0DAD).withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FaIcon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter your prompt',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _promptController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'E.g., "A tranquil meditation space in a forest clearing"',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: const Color(0xFF2A2A3E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6A0DAD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6A0DAD), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFF6A0DAD).withOpacity(0.5)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A3E),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  _generatedImageUrl!,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 300,
                      color: const Color(0xFF2A2A3E),
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6A0DAD)),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    log('Error loading image preview: $error');
                    return Container(
                      height: 300,
                      color: const Color(0xFF2A2A3E),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.broken_image,
                            color: Colors.white54,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load image preview',
                            style: TextStyle(color: Colors.white.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_appliedFilter != null)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getFilterColor(_appliedFilter!),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getFilterIcon(_appliedFilter!),
                        color: _getFilterColor(_appliedFilter!),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _appliedFilter!,
                        style: TextStyle(
                          color: _getFilterColor(_appliedFilter!),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Text(
        _errorMessage!,
        style: const TextStyle(color: Colors.red, fontSize: 14),
      ),
    );
  }

  Widget _buildGenerateButton(BuildContext context, String? userId, AiGalleryService aiGalleryService) {
    return SizedBox(
      width: double.infinity,
      child: _isGenerating
          ? Center(
        child: Column(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A0DAD)),
            ),
            const SizedBox(height: 16),
            Text(
              'Generating your image...\nThis may take up to 30 seconds.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      )
          : ElevatedButton(
        onPressed: () => _generateImage(context, userId, aiGalleryService),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A0DAD), Color(0xFF3700B3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                FaIcon(
                  FontAwesomeIcons.wandSparkles,
                  size: 18,
                  color: Colors.white,
                ),
                SizedBox(width: 12),
                Text(
                  'Generate Image',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPublishButton(BuildContext context, String? userId, String userName, AiGalleryService aiGalleryService) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _publishToGallery(context, userId, userName, aiGalleryService),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A0DAD), Color(0xFF3700B3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.cloud_upload, color: Colors.white, size: 18),
                SizedBox(width: 12),
                Text(
                  'Publish to Gallery',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegenerateButton(BuildContext context, String? userId, AiGalleryService aiGalleryService) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _generateImage(context, userId, aiGalleryService),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF6A0DAD)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            FaIcon(FontAwesomeIcons.wandSparkles, size: 18),
            SizedBox(width: 12),
            Text(
              'Regenerate Image',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6A0DAD).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✨ Tips for better results:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildTipItem('Be specific about style (e.g., "watercolor", "realistic", "3D render")'),
          _buildTipItem('Include details about lighting and atmosphere'),
          _buildTipItem('Mention color schemes you prefer'),
          _buildTipItem('Specify the perspective or viewpoint'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'Mystic Glow':
        return Colors.purple;
      case 'Nature Vibes':
        return Colors.green;
      case 'Psychedelic Burst':
        return Colors.orange;
      case 'Zen Serenity':
        return Colors.teal;
      default:
        return Colors.purple;
    }
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'Mystic Glow':
        return FontAwesomeIcons.moon;
      case 'Nature Vibes':
        return FontAwesomeIcons.leaf;
      case 'Psychedelic Burst':
        return FontAwesomeIcons.palette;
      case 'Zen Serenity':
        return FontAwesomeIcons.spa;
      default:
        return FontAwesomeIcons.wandSparkles;
    }
  }

  // Basic content moderation check
  bool _containsInappropriateContent(String text) {
    final lowerCaseText = text.toLowerCase();
    return _moderationWords.any((word) => lowerCaseText.contains(word));
  }

  // Get the filter prompt addition - updated for post-psychedelic retreat context
  String _getFilterPrompt(String filter) {
    switch (filter) {
      case 'Mystic Glow':
        return 'with a subtle ethereal quality and gentle luminosity, as if capturing a moment of spiritual insight after a profound experience';
      case 'Nature Vibes':
        return 'with natural elements that convey groundedness and connection to the earth, emphasizing harmony and organic beauty';
      case 'Psychedelic Burst':
        return 'with slightly enhanced colors and subtle patterns that hint at expanded awareness, while maintaining a balanced and integrative feel';
      case 'Zen Serenity':
        return 'with a peaceful, contemplative quality that embodies mindfulness and inner calm, perfect for integration after a transformative experience';
      default:
        return '';
    }
  }

  Future<void> _generateImage(BuildContext context, String? userId, AiGalleryService aiGalleryService) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first.')),
      );
      return;
    }

    var prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a prompt to generate an image.';
      });
      return;
    }

    // Check for inappropriate content
    if (_containsInappropriateContent(prompt)) {
      setState(() {
        _errorMessage = 'Your prompt may contain inappropriate content. Please revise and try again.';
      });
      return;
    }

    // Store the currently selected filter as the one being applied
    final currentFilter = _selectedFilter;

    // Add filter prompt if selected
    if (currentFilter != null) {
      prompt = '$prompt ${_getFilterPrompt(currentFilter)}';
    }

    setState(() {
      _isGenerating = true;
      _hasGeneratedImage = false;
      _errorMessage = null;
      _generatedImageUrl = null;
      _imageUrls = null;
    });

    try {
      // 1. Generate image from OpenAI
      final openAiUrl = await aiGalleryService.generateImageFromPrompt(prompt);

      // 2. Upload to Firebase with compression and optimization
      // This stores both thumbnail and full-resolution versions
      final imageUrls = await aiGalleryService.uploadAiImage(openAiUrl, userId);

      // 3. Update state with generated image URLs and applied filter
      setState(() {
        // Use the detail version for display
        _generatedImageUrl = imageUrls['detailUrl'];
        // Store all URLs for later use
        _imageUrls = imageUrls;
        _hasGeneratedImage = true;
        _isGenerating = false;
        _appliedFilter = currentFilter; // Store which filter was actually applied
      });
    } catch (e) {
      log('Error generating image: $e');
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Error generating image: ${e.toString()}';
      });
    }
  }

  Future<void> _publishToGallery(BuildContext context, String? userId, String userName, AiGalleryService aiGalleryService) async {
    if (userId == null || _generatedImageUrl == null || _imageUrls == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in and generate an image first.')),
      );
      return;
    }

    try {
      // Add image to Firestore gallery with all URLs and metadata
      await aiGalleryService.addAiImage(
        prompt: _appliedFilter != null
            ? '${_promptController.text.trim()} [${_appliedFilter}]'
            : _promptController.text.trim(),
        imageUrls: _imageUrls!,
        userId: userId,
        userName: userName,
      );

      // Schedule cleanup of old images if needed
      await aiGalleryService.scheduleCleanupIfNeeded();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ Image published to gallery successfully!'),
          backgroundColor: Color(0xFF6A0DAD),
        ),
      );

      // Navigate back to gallery
      Navigator.pop(context);
    } catch (e) {
      log('Error publishing to gallery: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error publishing to gallery: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}