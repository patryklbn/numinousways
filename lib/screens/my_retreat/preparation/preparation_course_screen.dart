import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/models/daymodule.dart';
import '/viewmodels/day_detail_provider.dart';
import '/widgets/preparation/daymodule_card.dart';
import 'day_detail_screen.dart';
import '/screens/my_retreat/preparation/pps_form_screen.dart';
import 'package:numinous_ways/viewmodels/preparation_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PreparationCourseScreen extends StatefulWidget {
  @override
  _PreparationCourseScreenState createState() => _PreparationCourseScreenState();
}

class _PreparationCourseScreenState extends State<PreparationCourseScreen> {
  final Color _accentColor = const Color(0xFFB4347F);

  @override
  void initState() {
    super.initState();
    // Load the data once when the screen is first built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PreparationProvider>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prepVM = context.watch<PreparationProvider>();

    return GestureDetector(
      // Add horizontal swipe detection for going back
      onHorizontalDragEnd: (details) {
        // If the swipe is from left to right with sufficient velocity
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          // Check if we can pop this route
          if (Navigator.of(context).canPop()) {
            // Pop the route to go back
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50], // Light background color
        body: RefreshIndicator(
          color: _accentColor,
          onRefresh: () => prepVM.loadData(),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1) Hero header with the "Start Course" button
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildHeroHeader(_accentColor),
                    if (prepVM.userStartDate == null && !prepVM.hasUserClickedStart)
                      Positioned(
                        bottom: -30, // Negative offset to overlay the button
                        right: 20,
                        child: _buildStartButton(prepVM),
                      ),
                  ],
                ),
              ),
              // 2) Body content with animated padding
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
                  curve: Curves.easeOutCubic,
                  child: _buildBodyContent(prepVM),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the hero header with a background image and back button.
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

  Widget _buildStartButton(PreparationProvider prepVM) {
    return ElevatedButton(
      onPressed: prepVM.startCourse,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: _accentColor,
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
    );
  }

  /// New progress bar widget matching the Integration screen style.
  Widget _buildProgressSection(double progressValue, int completedCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progressValue,
            backgroundColor: _accentColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "$completedCount/21 days completed",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _accentColor,
              ),
            ),
            Text(
              "${(progressValue * 100).toInt()}% complete",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _accentColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the main body content with introduction, progress bar, and module list.
  Widget _buildBodyContent(PreparationProvider prepVM) {
    if (prepVM.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prepVM.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[300], size: 48),
            const SizedBox(height: 16),
            Text(
              'Error: ${prepVM.errorMessage}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final modules = prepVM.allModules;
    final userStartDate = prepVM.userStartDate;

    // Compute progress for modules 1 to 21.
    final mainModules = modules.where((m) => m.dayNumber >= 1 && m.dayNumber <= 21).toList();
    final completedCount = mainModules.where((m) => m.isCompleted).length;
    const totalModules = 21;
    final progressValue = completedCount / totalModules;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Prepare for Your Journey",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _accentColor,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Complete this 21-day course with exercises, tasks, and meditations to thoroughly prepare yourself for your upcoming journey. This structured approach ensures you are mentally, emotionally, and spiritually ready.",
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.6,
              color: Colors.black
          ),
        ),
        const SizedBox(height: 32),

        if (userStartDate != null) ...[
          _buildProgressSection(progressValue, completedCount),
          const SizedBox(height: 16),
        ],

        Column(
          children: modules.map((module) {
            final isLast = module == modules.last;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline: vertical line and icon.
                SizedBox(
                  width: 40,
                  child: Column(
                    children: [
                      if (module != modules.first)
                        Container(
                          width: 2,
                          height: 20,
                          color: Colors.grey[400],
                        ),
                      Icon(
                        module.isLocked
                            ? Icons.lock
                            : (module.isCompleted ? Icons.check_circle_outline : Icons.lock_open_outlined),
                        color: module.isLocked ? Colors.grey : (module.isCompleted ? Colors.green : _accentColor),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 20,
                          color: Colors.grey[400],
                        ),
                    ],
                  ),
                ),
                // Module card with animation
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 400 + (modules.indexOf(module) * 100)),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _onModuleTap(prepVM, module),
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: _accentColor.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: DayModuleCard(module: module),
                          ),
                        ),
                      ),
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

  /// Called when a module tile is tapped.
  Future<void> _onModuleTap(PreparationProvider prepVM, DayModule module) async {
    if (module.isLocked) return; // Do nothing if the module is locked.

    // Handle special cases for Day 0 and Day 22.
    if (module.dayNumber == 0) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PPSFormScreen(
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

    if (module.dayNumber == 22) {
      final ppsResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PPSFormScreen(
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

    // Normal day detail navigation.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<DayDetailProvider>(
          create: (_) => DayDetailProvider(
            dayNumber: module.dayNumber,
            isDayCompletedInitially: module.isCompleted,
            firestoreInstance: FirebaseFirestore.instance,
            userId: prepVM.userId!,
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