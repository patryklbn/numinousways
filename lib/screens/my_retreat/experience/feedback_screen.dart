import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/retreat_service.dart';

class FeedbackScreen extends StatefulWidget {
  final String retreatId;
  final String userId;

  const FeedbackScreen({
    Key? key,
    required this.retreatId,
    required this.userId,
  }) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isSubmitting = false;

  // Scoring variables
  double _overallExperience = 1;
  double _securitySupport = 1;
  double _groupVsFreeTime = 5;
  double _comfortFacilities = 1;

  // Controllers
  final TextEditingController _enhanceSecurityCtrl = TextEditingController();
  final TextEditingController _smallGroupFeedbackCtrl = TextEditingController();
  final TextEditingController _facilitationFeedbackCtrl = TextEditingController();
  final TextEditingController _highlightCtrl = TextEditingController();
  final TextEditingController _challengingCtrl = TextEditingController();
  final TextEditingController _makeBetterCtrl = TextEditingController();
  final TextEditingController _recommendationCtrl = TextEditingController();
  final TextEditingController _additionalThoughtsCtrl = TextEditingController();

  // Theme colors
  final Color _primaryColor = const Color(0xFF6A0DAD);
  final Color _secondaryColor = const Color(0xFF3700B3);
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF333333);

  @override
  void dispose() {
    _scrollController.dispose();
    _enhanceSecurityCtrl.dispose();
    _smallGroupFeedbackCtrl.dispose();
    _facilitationFeedbackCtrl.dispose();
    _highlightCtrl.dispose();
    _challengingCtrl.dispose();
    _makeBetterCtrl.dispose();
    _recommendationCtrl.dispose();
    _additionalThoughtsCtrl.dispose();
    super.dispose();
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
          if (icon != null) Icon(icon, color: _primaryColor),
          if (icon != null) const SizedBox(width: 8),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    int maxLines = 3,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
            child: Row(
              children: [
                if (icon != null) Icon(icon, size: 18, color: _primaryColor),
                if (icon != null) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(
              color: _textColor,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              fillColor: _cardColor,
              filled: true,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _primaryColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection({
    required String title,
    required String description,
    required double value,
    required Function(double) onChanged,
    required double min,
    required double max,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) Icon(icon, size: 20, color: _primaryColor),
              if (icon != null) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                value.toStringAsFixed(0),
                style: TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            activeColor: _primaryColor,
            inactiveColor: _primaryColor.withOpacity(0.2),
            onChanged: onChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                min.toInt().toString(),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                max.toInt().toString(),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
          _buildSectionHeader(title),
          ...children,
        ],
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final feedbackData = {
      'overallExperience': _overallExperience,
      'securitySupport': _securitySupport,
      'enhanceSecurity': _enhanceSecurityCtrl.text.trim(),
      'smallGroupFeedback': _smallGroupFeedbackCtrl.text.trim(),
      'facilitationFeedback': _facilitationFeedbackCtrl.text.trim(),
      'highlight': _highlightCtrl.text.trim(),
      'challenging': _challengingCtrl.text.trim(),
      'groupVsFreeTime': _groupVsFreeTime,
      'comfortFacilities': _comfortFacilities,
      'makeBetter': _makeBetterCtrl.text.trim(),
      'recommendation': _recommendationCtrl.text.trim(),
      'additionalThoughts': _additionalThoughtsCtrl.text.trim(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      final retreatService = Provider.of<RetreatService>(context, listen: false);
      await retreatService.submitFeedback(
        widget.retreatId,
        widget.userId,
        feedbackData,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Thank you for your feedback!"),
          backgroundColor: _primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error submitting feedback: $e"),
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
          "Retreat Feedback",
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
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    "About Your Feedback",
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: const Text(
                    "Your feedback helps us improve future retreats and better understand the impact of our programs. All responses are confidential and valuable.",
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
              children: [
                // Introduction Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.feedback_outlined, color: _primaryColor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "We value your feedback! Your insights help us create better experiences for future participants.",
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

                // Overall Experience Section
                _buildFormSection(
                  "Overall Experience",
                  [
                    _buildRatingSection(
                      title: "How would you rate your overall experience?",
                      description: "1 = Poor, 10 = Excellent",
                      value: _overallExperience,
                      onChanged: (value) => setState(() => _overallExperience = value),
                      min: 1,
                      max: 10,
                      icon: Icons.star_outline,
                    ),
                    _buildRatingSection(
                      title: "How secure and supported did you feel?",
                      description: "1 = Not at all, 10 = Completely",
                      value: _securitySupport,
                      onChanged: (value) => setState(() => _securitySupport = value),
                      min: 1,
                      max: 10,
                      icon: Icons.security,
                    ),
                    _buildTextField(
                      controller: _enhanceSecurityCtrl,
                      label: "What could enhance your sense of security?",
                      hintText: "Share your suggestions...",
                      icon: Icons.psychology,
                    ),
                  ],
                ),

                // Group Experience Section
                _buildFormSection(
                  "Group Experience",
                  [
                    _buildTextField(
                      controller: _smallGroupFeedbackCtrl,
                      label: "How was your small group experience?",
                      hintText: "Share your thoughts about group dynamics...",
                      icon: Icons.groups,
                    ),
                    _buildRatingSection(
                      title: "Balance of group activities vs free time",
                      description: "0 = Too many group activities, 10 = Too much free time",
                      value: _groupVsFreeTime,
                      onChanged: (value) => setState(() => _groupVsFreeTime = value),
                      min: 0,
                      max: 10,
                      icon: Icons.balance,
                    ),
                  ],
                ),

                // Highlights and Challenges Section
                _buildFormSection(
                  "Highlights & Challenges",
                  [
                    _buildTextField(
                      controller: _highlightCtrl,
                      label: "What were your highlights?",
                      hintText: "Share your favorite moments or insights...",
                      icon: Icons.lightbulb_outline,
                    ),
                    _buildTextField(
                      controller: _challengingCtrl,
                      label: "What challenges did you face?",
                      hintText: "Share any difficulties or concerns...",
                      icon: Icons.trending_up,
                    ),
                  ],
                ),

                // Facilities and Comfort Section
                _buildFormSection(
                  "Facilities & Accommodation",
                  [
                    _buildRatingSection(
                      title: "How comfortable were the facilities?",
                      description: "1 = Not comfortable, 10 = Extremely comfortable",
                      value: _comfortFacilities,
                      onChanged: (value) => setState(() => _comfortFacilities = value),
                      min: 1,
                      max: 10,
                      icon: Icons.hotel,
                    ),
                  ],
                ),

                // Improvements and Recommendations Section
                _buildFormSection(
                  "Improvements & Recommendations",
                  [
                    _buildTextField(
                      controller: _makeBetterCtrl,
                      label: "How can we improve?",
                      hintText: "Share your suggestions for future retreats...",
                      icon: Icons.auto_fix_high,
                    ),
                    _buildTextField(
                      controller: _recommendationCtrl,
                      label: "Would you recommend this retreat?",
                      hintText: "Tell us why or why not...",
                      icon: Icons.recommend,
                    ),
                    _buildTextField(
                      controller: _additionalThoughtsCtrl,
                      label: "Additional Thoughts",
                      hintText: "Any other feedback you'd like to share...",
                      icon: Icons.more_horiz,
                      maxLines: 4,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Submit Button
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
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.send_rounded),
                        SizedBox(width: 8),
                        Text(
                          "SUBMIT FEEDBACK",
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