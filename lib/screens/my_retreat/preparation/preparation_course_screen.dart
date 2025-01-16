import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/models/daymodule.dart';
import '/viewmodels/day_detail_provider.dart';
import '/widgets/preparation/daymodule_card.dart';
import 'day_detail_screen.dart';
import '/screens/my_retreat/preparation/pps_form_screen.dart';
import 'package:numinous_way/viewmodels/preparation_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class PreparationCourseScreen extends StatefulWidget {
  @override
  _PreparationCourseScreenState createState() => _PreparationCourseScreenState();
}

class _PreparationCourseScreenState extends State<PreparationCourseScreen> {
  @override
  void initState() {
    super.initState();
    // Load the data once, or you could do this in a FutureBuilder
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PreparationProvider>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prepVM = context.watch<PreparationProvider>();
    final accentColor = const Color(0xFFB4347F);

    // A pull-to-refresh calls prepVM.loadData()
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => prepVM.loadData(),
        child: CustomScrollView(
          slivers: [
            // 1) The hero header + "Start Course" button stack
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildHeroHeader(accentColor),
                  // The button is only shown if user hasn't started
                  if (prepVM.userStartDate == null &&
                      !prepVM.hasUserClickedStart)
                    Positioned(
                      bottom: -30, // negative offset for overlay
                      right: 20,
                      child: ElevatedButton(
                        onPressed: prepVM.startCourse,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Start Course',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 2) Body content (padding depends on the button presence)
            SliverToBoxAdapter(
              child: AnimatedPadding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  (prepVM.userStartDate == null && !prepVM.hasUserClickedStart)
                      ? 50
                      : 20,
                  20,
                  20,
                ),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _buildBodyContent(prepVM, accentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The top "hero" header that is 250px high, with a background image and back button
  Widget _buildHeroHeader(Color accentColor) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: Container(
        height: 250.0,
        color: accentColor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/myretreat/preparation.png',
              fit: BoxFit.cover,
            ),
            Container(color: Colors.black.withOpacity(0.3)),
            Positioned(
              top: 40,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Text(
                "21 Day Preparation",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 2),
                      blurRadius: 4.0,
                      color: Colors.black54,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The body content: the introduction text, progress bar, and the modules list
  Widget _buildBodyContent(PreparationProvider prepVM, Color accentColor) {
    // Show loading indicator or error
    if (prepVM.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prepVM.errorMessage != null) {
      return Center(
        child: Text(
          'Error: ${prepVM.errorMessage}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    // If data loaded
    final modules = prepVM.allModules;
    final userStartDate = prepVM.userStartDate;

    // Compute progress for days 1..21
    final mainModules = modules.where((m) =>
    m.dayNumber >= 1 && m.dayNumber <= 21).toList();
    final completedCount = mainModules
        .where((m) => m.isCompleted)
        .length;
    const totalModules = 21;
    final progressValue = completedCount / totalModules;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Prepare for Your Journey" heading
        Text(
          "Prepare for Your Journey",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 8),

        // Original description text
        const Text(
          "Complete this 21-day course with exercises, tasks, and meditations "
              "to thoroughly prepare yourself for your upcoming journey. This structured "
              "approach ensures you are mentally, emotionally, and spiritually ready.",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 24),

        // Show progress if user has started the course
        if (userStartDate != null) ...[
          LinearProgressIndicator(
            value: progressValue,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),
          const SizedBox(height: 8),
          Text(
            "$completedCount/$totalModules days completed",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
        ],

        // List of modules
        Column(
          children: modules.map((module) {
            final isLast = module.dayNumber == modules.last.dayNumber;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The vertical line & icon timeline
                SizedBox(
                  width: 40,
                  child: Column(
                    children: [
                      // If not the first module, show the line above
                      if (module.dayNumber != modules.first.dayNumber)
                        Container(
                          width: 2,
                          height: 20,
                          color: Colors.grey[400],
                        ),
                      Icon(
                        module.isLocked
                            ? Icons.lock
                            : (module.isCompleted
                            ? Icons.check_circle_outline
                            : Icons.lock_open_outlined),
                        color: module.isLocked
                            ? Colors.grey
                            : (module.isCompleted ? Colors.green : accentColor),
                      ),
                      // If not the last module, show the line below
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 20,
                          color: Colors.grey[400],
                        ),
                    ],
                  ),
                ),
                // The day card
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
                    child: GestureDetector(
                      onTap: () => _onModuleTap(prepVM, module),
                      child: DayModuleCard(module: module),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        )
      ],
    );
  }

  /// Called when user taps a module tile in the list
  Future<void> _onModuleTap(PreparationProvider prepVM,
      DayModule module) async {
    if (module.isLocked) return; // do nothing if locked

    // Day 0 => PPS (Before)
    if (module.dayNumber == 0) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PPSFormScreen(
                isBeforeCourse: true,
                userId: prepVM.userId,
              ),
        ),
      );
      if (result == true) {
        await prepVM.markModuleCompleted(0);
      }
      return;
    }

    // Day 22 => PPS (After)
    if (module.dayNumber == 22) {
      final ppsResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PPSFormScreen(
                isBeforeCourse: false,
                userId: prepVM.userId,
              ),
        ),
      );
      if (ppsResult == true) {
        await prepVM.markModuleCompleted(22);
      }
      return;
    }

// Normal day detail
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChangeNotifierProvider<DayDetailProvider>(
              create: (_) =>
                  DayDetailProvider(
                    dayNumber: module.dayNumber,
                    isDayCompletedInitially: module.isCompleted,
                    firestoreInstance: FirebaseFirestore.instance,
                    userId: prepVM.userId!, // Ensure this value is available
                  ),
              child: DayDetailScreen(
                dayNumber: module.dayNumber,
                isDayCompleted: module.isCompleted,
              ),
            ),
      ),
    );
    if (result == true) {
      await prepVM.markModuleCompleted(module.dayNumber);
    }
  }
}