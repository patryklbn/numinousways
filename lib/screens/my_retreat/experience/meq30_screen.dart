import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/retreat_service.dart';
import '../../../models/experience/meq_submission.dart';
import '../../../models/experience/participant.dart';

/// 30 MEQ questions for each experience (1 & 2).
final List<String> meqQuestions = [
  "Loss of your usual sense of time. (T)",
  "Experience of amazement. (P)",
  "Sense that the experience cannot be described adequately in words. (I)",
  "Gain of insightful knowledge at an intuitive level",
  "Feeling that you experienced eternity or infinity.",
  "Experience of oneness or unity with objects or persons around you.",
  "Loss of your usual sense of space. (T)",
  "Feelings of tenderness and gentleness. (P)",
  "Certainty of encounter with ultimate reality...",
  "Feeling you couldn't do justice to your experience in words. (I)",
  "Loss of your usual sense of where you were. (T)",
  "Feelings of peace and tranquility. (P)",
  "Sense of being outside of time, beyond past & future. (T)",
  "Freedom from limitations of your personal self...",
  "Sense of being at a spiritual height.",
  "Experience of pure being & pure awareness.",
  "Experience of ecstasy. (P)",
  "Insight that “all is One”.",
  "Being in a realm with no space boundaries. (T)",
  "Experience of oneness in an “inner world” within.",
  "Sense of reverence.",
  "Experience of timelessness. (T)",
  "Convinced you encountered ultimate reality...",
  "Feeling you experienced something profoundly sacred & holy.",
  "Awareness of the living presence in all things.",
  "Fusion of your personal self into a larger whole.",
  "Sense of awe or awesomeness. (P)",
  "Unity with ultimate reality.",
  "Difficult to communicate your experience to others. (I)",
  "Feelings of joy. (P)",
];

class MEQ30Screen extends StatefulWidget {
  final String retreatId;
  final Participant participant;

  const MEQ30Screen({
    Key? key,
    required this.retreatId,
    required this.participant,
  }) : super(key: key);

  @override
  State<MEQ30Screen> createState() => _MEQ30ScreenState();
}

class _MEQ30ScreenState extends State<MEQ30Screen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameCtrl = TextEditingController();

  // Each set for Experience 1 or 2 => "meq1_1..meq1_30", "meq2_1..meq2_30"
  final Map<String, double> meq1Answers = {};
  final Map<String, double> meq2Answers = {};

  // Booleans to lock each experience separately
  bool _lockExp1 = false;
  bool _lockExp2 = false;

  bool _initialized = false; // For loading spinner

  // Gradient colors to use across the screen
  final Color _gradientColor1 = const Color(0xFF6A0DAD);
  final Color _gradientColor2 = const Color(0xFF3700B3);

  @override
  void initState() {
    super.initState();

    // Setup the TabController & listen for tab changes (to update button text)
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // rebuild to update the button text
    });

    // Pre-fill name from participant
    _nameCtrl.text = widget.participant.name.isNotEmpty
        ? widget.participant.name
        : widget.participant.nickname;

    // Initialize all answers to 0.0
    for (int i = 1; i <= 30; i++) {
      meq1Answers["meq1_$i"] = 0.0;
      meq2Answers["meq2_$i"] = 0.0;
    }

    // Fetch existing data from Firestore (if user partially completed or locked)
    _fetchExistingSubmission();
  }

  @override
  void dispose() {
    _tabController.removeListener(() {});
    _tabController.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchExistingSubmission() async {
    setState(() => _initialized = false);
    try {
      final retreatService = Provider.of<RetreatService>(context, listen: false);
      final existing = await retreatService.getMEQSubmission(
        widget.retreatId,
        widget.participant.userId,
      );
      if (existing != null) {
        // Fill in existing name, meq1Answers, meq2Answers, lock states
        _nameCtrl.text = existing.nameOrPseudonym;
        for (final e in existing.meq1Answers.entries) {
          meq1Answers[e.key] = e.value;
        }
        for (final e in existing.meq2Answers.entries) {
          meq2Answers[e.key] = e.value;
        }
        _lockExp1 = existing.completedExp1;
        _lockExp2 = existing.completedExp2;
      }
    } catch (e) {
      print("Error fetching MEQ submission: $e");
    } finally {
      setState(() => _initialized = true);
    }
  }

  /// Submits only the current tab's experience
  Future<void> _submitCurrentExperience() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Name/Pseudonym Required"),
          content: const Text(
            "Please provide a name or pseudonym to identify your MEQ-30 submission.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    // Figure out which experience we are on
    final index = _tabController.index;
    final isExp1 = (index == 0);

    // If it's already locked, do nothing
    if (isExp1 && _lockExp1) return;
    if (!isExp1 && _lockExp2) return;

    try {
      final retreatService = Provider.of<RetreatService>(context, listen: false);
      final existing = await retreatService.getMEQSubmission(
        widget.retreatId,
        widget.participant.userId,
      );

      bool oldLockExp1 = existing?.completedExp1 ?? false;
      bool oldLockExp2 = existing?.completedExp2 ?? false;

      final oldMeq1 = existing?.meq1Answers ?? {};
      final oldMeq2 = existing?.meq2Answers ?? {};

      // Merge old answers if that experience was locked
      for (final e in oldMeq1.entries) {
        if (oldLockExp1) {
          meq1Answers[e.key] = e.value; // preserve locked answers
        }
      }
      for (final e in oldMeq2.entries) {
        if (oldLockExp2) {
          meq2Answers[e.key] = e.value; // preserve locked answers
        }
      }

      bool newLockExp1 = oldLockExp1;
      bool newLockExp2 = oldLockExp2;

      // Lock only the current experience
      if (isExp1) {
        newLockExp1 = true;
      } else {
        newLockExp2 = true;
      }

      final updatedSubmission = MEQSubmission(
        userId: widget.participant.userId,
        nameOrPseudonym: name,
        dateSubmitted: DateTime.now(),
        meq1Answers: meq1Answers,
        meq2Answers: meq2Answers,
        completedExp1: newLockExp1,
        completedExp2: newLockExp2,
      );

      await retreatService.submitMEQSubmission(widget.retreatId, updatedSubmission);

      setState(() {
        _lockExp1 = newLockExp1;
        _lockExp2 = newLockExp2;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("MEQ-30 submitted successfully.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting MEQ: $e")),
      );
    }
  }

  /// Show a dialog with the full introduction + "OK" button
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("MEQ-30 Instructions"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Looking back on the entirety of your psychedelic session(s), "
                    "please rate the intensity of each phenomenon you experienced.\n\n"
                    "Use a scale of 0 to 5:\n"
                    "0 = none/not at all\n"
                    "1 = so slight cannot decide\n"
                    "2 = slight\n"
                    "3 = moderate\n"
                    "4 = strong\n"
                    "5 = extreme (more than any other time in your life)\n\n"
                    "Try to recall the entirety of your experience, from start to finish, "
                    "and answer honestly based on how you felt at the time.",
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /// Button builder that shows a gradient if enabled, grey if disabled.
  Widget _buildGradientButton({
    required String text,
    required VoidCallback? onPressed,
    required bool disabled,
  }) {
    return Container(
      // If disabled => color = grey; if enabled => gradient.
      decoration: BoxDecoration(
        color: disabled ? Colors.grey : null,
        gradient: disabled
            ? null
            : LinearGradient(
          colors: [_gradientColor1, _gradientColor2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, // Let container color show
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: onPressed, // null => disabled
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = _initialized ? _tabController.index : 0;
    final isExp1 = (index == 0);

    // Button text changes based on the active tab
    final buttonText = isExp1 ? "Submit Experience 1" : "Submit Experience 2";

    // If the experience is locked, disable the button (onPressed => null)
    final currentTabLocked = isExp1 ? _lockExp1 : _lockExp2;
    final VoidCallback? onPressed =
    currentTabLocked ? null : _submitCurrentExperience;

    return Scaffold(
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
          "MEQ-30 Form",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Experience 1"),
            Tab(text: "Experience 2"),
          ],
        ),
      ),
      body: SafeArea(
        child: !_initialized
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      "Please use a scale from 0 to 5 for each question.\nTap the help icon for more details.",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline),
                    onPressed: _showHelpDialog,
                  ),
                ],
              ),
            ),

            // Name field with gradient borders (editable)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: "Name/Pseudonym *",
                  hintText: "Used to identify your MEQ submission",
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _gradientColor1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                    BorderSide(color: _gradientColor2, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Tab bar view (2 experiences)
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMeqList(isExperience1: true),
                  _buildMeqList(isExperience1: false),
                ],
              ),
            ),

            // Gradient (or grey) button at bottom
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildGradientButton(
                text: buttonText,
                onPressed: onPressed,
                disabled: currentTabLocked,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeqList({required bool isExperience1}) {
    final locked = isExperience1 ? _lockExp1 : _lockExp2;
    final answerMap = isExperience1 ? meq1Answers : meq2Answers;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: meqQuestions.length,
      itemBuilder: (context, i) {
        final idx = i + 1;
        final key = (isExperience1 ? "meq1_" : "meq2_") + idx.toString();
        final label = "${idx}) ${meqQuestions[i]}";
        final currentVal = answerMap[key] ?? 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            Slider(
              min: 0,
              max: 5,
              divisions: 5,
              value: currentVal,
              label: currentVal.round().toString(),
              onChanged: locked
                  ? null
                  : (val) {
                setState(() {
                  answerMap[key] = val;
                });
              },
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}
