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

  double _overallExperience = 1; // 1..10
  double _securitySupport = 1;   // 1..10
  double _groupVsFreeTime = 5;   // 0..10: 0=too many group activities, 10=too much free time
  double _comfortFacilities = 1; // 1..10

  // Open-ended questions
  final TextEditingController _enhanceSecurityCtrl = TextEditingController();
  final TextEditingController _smallGroupFeedbackCtrl = TextEditingController();
  final TextEditingController _facilitationFeedbackCtrl = TextEditingController();
  final TextEditingController _highlightCtrl = TextEditingController();
  final TextEditingController _challengingCtrl = TextEditingController();
  final TextEditingController _makeBetterCtrl = TextEditingController();
  final TextEditingController _recommendationCtrl = TextEditingController();
  final TextEditingController _additionalThoughtsCtrl = TextEditingController();

  // Gradient colors to use across the screen
  final Color _gradientColor1 = const Color(0xFF6A0DAD);
  final Color _gradientColor2 = const Color(0xFF3700B3);

  @override
  void dispose() {
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

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final feedbackData = {
      'overallExperience': _overallExperience,
      'securitySupport': _securitySupport,
      'enhanceSecurity': _enhanceSecurityCtrl.text.trim(),
      'smallGroupFeedback': _smallGroupFeedbackCtrl.text.trim(),
      'facilitationFeedback': _facilitationFeedbackCtrl.text.trim(),
      'highlight': _highlightCtrl.text.trim(),
      'challenging': _challengingCtrl.text.trim(),
      'groupVsFreeTime': _groupVsFreeTime,
      'atmosphere': "",
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
        const SnackBar(content: Text("Thank you for your feedback!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting feedback: $e")),
      );
    }
  }

  // Helper to build a label widget
  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    );
  }

  // Helper to build a gradient text field with custom borders.
  Widget _buildGradientTextField({
    TextEditingController? controller,
    required String hintText,
    int maxLines = 3,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderSide: BorderSide(color: _gradientColor1),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _gradientColor1),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _gradientColor2, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        hintText: hintText,
      ),
    );
  }

  // Helper to build a slider.
  Widget _buildSlider({
    required double minVal,
    required double maxVal,
    required double currentVal,
    required Function(double) onChange,
  }) {
    return Slider(
      min: minVal,
      max: maxVal,
      divisions: (maxVal - minVal).toInt(),
      value: currentVal,
      label: currentVal.toStringAsFixed(0),
      onChanged: (val) => setState(() => onChange(val)),
    );
  }

  // Helper method to build a gradient button with bold text.
  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_gradientColor1, _gradientColor2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: onPressed,
        child: const Text(
          "Submit",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a gradient AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_gradientColor1, _gradientColor2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "Retreat Feedback",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // 1) Overall Experience (1..10)
                _buildLabel("1) On a scale from 1 to 10, how would you rate the overall experience of the retreat?"),
                _buildSlider(
                  minVal: 1,
                  maxVal: 10,
                  currentVal: _overallExperience,
                  onChange: (val) => setState(() => _overallExperience = val),
                ),
                // 2) Security/Support (1..10)
                _buildLabel("2) On a scale from 1 to 10, how secure & supported did you feel? (1 = not at all, 10 = extremely)"),
                _buildSlider(
                  minVal: 1,
                  maxVal: 10,
                  currentVal: _securitySupport,
                  onChange: (val) => setState(() => _securitySupport = val),
                ),
                // 3) Enhance sense of security?
                _buildLabel("3) What could have enhanced your sense of security or comfort?"),
                _buildGradientTextField(
                  controller: _enhanceSecurityCtrl,
                  hintText: "Share your ideas...",
                ),
                const SizedBox(height: 20),
                // 4) Feedback about small group
                _buildLabel("4) Any particular feedback about your small group?"),
                _buildGradientTextField(
                  controller: _smallGroupFeedbackCtrl,
                  hintText: "Thoughts about small group dynamics...",
                ),
                const SizedBox(height: 20),
                // 5) Facilitation feedback
                _buildLabel("5) Facilitation: What was your experience of the team or individual facilitators?"),
                _buildGradientTextField(
                  controller: _facilitationFeedbackCtrl,
                  hintText: "Share your facilitator feedback...",
                ),
                const SizedBox(height: 20),
                // 6) Highlight
                _buildLabel("6) What stood out as a highlight for you?"),
                _buildGradientTextField(
                  controller: _highlightCtrl,
                  hintText: "Favorite moment, reflection, or insight?",
                ),
                const SizedBox(height: 20),
                // 7) Challenging
                _buildLabel("7) Any parts you didn't vibe with or found challenging?"),
                _buildGradientTextField(
                  controller: _challengingCtrl,
                  hintText: "What was difficult for you?",
                ),
                const SizedBox(height: 20),
                // 8) Group vs Personal Time (0..10)
                _buildLabel("8) How did you feel about the balance between group activities & free time? (0 = too many group activities, 10 = too much free time)"),
                _buildSlider(
                  minVal: 0,
                  maxVal: 10,
                  currentVal: _groupVsFreeTime,
                  onChange: (val) => setState(() => _groupVsFreeTime = val),
                ),
                // 9) Atmosphere among participants
                _buildLabel("9) How would you describe the atmosphere & dynamics among participants?"),
                _buildGradientTextField(
                  hintText: "Group synergy, vibe, conflicts, positivity?",
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                // 10) Comfort of accommodations/facilities
                _buildLabel("10) Rate your comfort with the accommodations/facilities (1..10)"),
                _buildSlider(
                  minVal: 1,
                  maxVal: 10,
                  currentVal: _comfortFacilities,
                  onChange: (val) => setState(() => _comfortFacilities = val),
                ),
                // 11) Make better
                _buildLabel("11) How can we make our next retreat better for attendees like you?"),
                _buildGradientTextField(
                  controller: _makeBetterCtrl,
                  hintText: "Any suggestions, improvements, or new ideas?",
                ),
                const SizedBox(height: 20),
                // 12) Recommendation
                _buildLabel("12) Would you suggest these retreats to your circle? Why or why not?"),
                _buildGradientTextField(
                  controller: _recommendationCtrl,
                  hintText: "Yes, no, maybe so? Let us know why.",
                ),
                const SizedBox(height: 20),
                // 13) Additional thoughts
                _buildLabel("13) Any additional thoughts? Could be about the venue, meals, recommended reads, etc."),
                _buildGradientTextField(
                  controller: _additionalThoughtsCtrl,
                  hintText: "Feel free to expand on any other topics...",
                  maxLines: 4,
                ),
                const SizedBox(height: 20),
                // Submit button using gradient style
                _buildGradientButton(
                  text: "Submit",
                  onPressed: _submitFeedback,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
