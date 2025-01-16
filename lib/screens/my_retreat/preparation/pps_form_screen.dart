import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A screen that shows 20 PPS questions (1–7 range).
/// [isBeforeCourse] = true if the user is filling the form before starting the course.
class PPSFormScreen extends StatefulWidget {
  final bool isBeforeCourse;
  final String userId; // We need userId to save data under /users/{userId}/ppsForms

  PPSFormScreen({required this.isBeforeCourse, required this.userId});

  @override
  _PPSFormScreenState createState() => _PPSFormScreenState();
}

class _PPSFormScreenState extends State<PPSFormScreen> {
  final Color accentColor = Color(0xFFB4347F);  // Accent color for styling
  final List<String> answerLabels = [
    "not at all",
    "a little",
    "more than a little",
    "moderately",
    "considerably",
    "very much",
    "completely"
  ];

  Map<int, int> _answers = {};
  bool _isSubmitted = false;  // Tracks if the form was submitted

  final List<String> _questions = [
    "I have done my own research into the psychedelic substance.",
    "I understand the experience might evoke a range of intense emotions.",
    "I have a clear intention for the psychedelic experience.",
    "I have carefully contemplated my reasons for taking a psychedelic.",
    "I understand that past events may surface during the experience.",
    "I know the experience will be somewhat unpredictable.",
    "I have spoken with a therapist/counselor in preparation.",
    "I am ready to experience whatever comes up.",
    "I am prepared to deal with uncomfortable aspects.",
    "I feel ready to surrender to whatever happens.",
    "I feel psychologically prepared for the experience.",
    "I am prepared for the physical effects of the psychedelic.",
    "I feel a positive connection with those around me during the experience.",
    "I feel the substance is safe to take.",
    "I trust my mind and body to process the experience safely.",
    "I am aware the experience might change me.",
    "My friends/family are prepared for the changes that could occur.",
    "I have engaged in preparation practices (meditation, yoga, etc.).",
    "I have made a plan for the hours/days after the experience.",
    "I have strategies in case things get difficult during the experience.",
  ];

  @override
  void initState() {
    super.initState();
    // Initialize each answer to 4 (moderately)
    for (int i = 0; i < _questions.length; i++) {
      _answers[i] = 4;
    }
    _checkSubmission();
  }

  Future<void> _checkSubmission() async {
    final docId = widget.isBeforeCourse ? "before" : "after";

    final docRef = FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .collection("ppsForms")
        .doc(docId);
    final docSnap = await docRef.get();

    if (docSnap.exists && docSnap.data() != null) {
      final data = docSnap.data();
      Map<String, dynamic>? answersMap = data?["answers"];

      if (answersMap != null) {
        answersMap.forEach((key, value) {
          final index = int.tryParse(key.substring(1))! - 1;
          _answers[index] = value as int;
        });
      }
      setState(() {
        _isSubmitted = true;
      });
    }
  }

  Future<void> _submitAnswers() async {
    final Map<String, int> answersMap = {};
    _answers.forEach((index, rating) {
      answersMap["q${index + 1}"] = rating;
    });

    final docId = widget.isBeforeCourse ? "before" : "after";
    final docRef = FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .collection("ppsForms")
        .doc(docId);

    await docRef.set({
      "answers": answersMap,
      "dateSubmitted": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() {
      _isSubmitted = true;
    });
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isBeforeCourse
        ? "PPS (Before Course)"
        : "PPS (After Course)";

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: accentColor,
      ),
      body: ListView.builder(
        itemCount: _questions.length,
        itemBuilder: (context, i) => _buildQuestionTile(i),
      ),
      floatingActionButton: _isSubmitted
          ? null
          : FloatingActionButton(
        onPressed: _submitAnswers,
        backgroundColor: accentColor,
        child: Icon(Icons.check, color: Colors.white),
      ),
    );
  }

  Widget _buildQuestionTile(int index) {
    int currentAnswer = _answers[index] ?? 4;
    String currentLabel = answerLabels[currentAnswer - 1];

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Q${index + 1}. ${_questions[index]}",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Slider(
              value: currentAnswer.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              label: currentLabel,
              activeColor: accentColor,
              inactiveColor: accentColor.withOpacity(0.3),
              onChanged: _isSubmitted
                  ? null
                  : (val) {
                setState(() {
                  _answers[index] = val.toInt();
                });
              },
            ),
            Text(
              "Answer: $currentLabel",
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
