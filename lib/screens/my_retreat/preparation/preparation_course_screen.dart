import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/models/daymodule.dart';
import '/widgets/preparation/daymodule_card.dart';
import 'day_detail_screen.dart';
import '/services/login_provider.dart';
import '/services/preparation_course_service.dart';
import '/screens/my_retreat/preparation/pps_form_screen.dart';

class PreparationCourseScreen extends StatefulWidget {
  @override
  _PreparationCourseScreenState createState() => _PreparationCourseScreenState();
}

class _PreparationCourseScreenState extends State<PreparationCourseScreen> {
  DateTime? userStartDate;
  List<DayModule> allModules = [];
  bool _isLoading = true;

  final PreparationCourseService _prepService =
  PreparationCourseService(FirebaseFirestore.instance);
  String? _userId;

  bool _hasDoneBeforePPS = false; // if user did Day 0 form
  bool _hasDoneAfterPPS = false;  // if user did Day 22 form

  /// Local flag to hide the "Start Course" button once pressed
  bool _hasUserClickedStart = false;

  @override
  void initState() {
    super.initState();
    // Post-frame: fetch data & check PPS forms
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _userId = Provider.of<LoginProvider>(context, listen: false).userId;
      await _loadUserData();

      if (_userId != null) {
        _hasDoneBeforePPS = await _prepService.hasPPSForm(_userId!, true);
        _hasDoneAfterPPS = await _prepService.hasPPSForm(_userId!, false);
      }
      setState(() {});
    });
  }

  /// Loads user data (modules array + startDate) from Firestore.
  /// If no modules exist, create day 0..22. Also handle future startDate => reset.
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    final userData = await _prepService.getUserPreparationData(_userId!);
    DateTime? start;
    List<DayModule> userModules = [];
    bool didReset = false; // Flag to track if reset occurred

    if (userData != null) {
      // Parse startDate if available
      if (userData['startDate'] != null) {
        start = (userData['startDate'] as Timestamp).toDate();
      }

      // Parse modules if they exist
      if (userData['modules'] != null && userData['modules'] is List) {
        for (var m in userData['modules']) {
          userModules.add(DayModule.fromMap(m));
        }
      }
    }

    // Initialize modules if they don't exist
    if (userModules.isEmpty) {
      userModules = _generateDefaultModules();
      await _prepService.updateModuleState(_userId!, userModules);
    } else {
      // Ensure Day 0 & Day 22 exist in modules
      bool changed = false;
      if (!userModules.any((mod) => mod.dayNumber == 0)) {
        userModules.insert(
          0,
          DayModule(
            dayNumber: 0,
            title: 'PPS (Before)',
            description: 'Pre-Course PPS Form',
            isLocked: true,
            isCompleted: false,
          ),
        );
        changed = true;
      }
      if (!userModules.any((mod) => mod.dayNumber == 22)) {
        userModules.add(
          DayModule(
            dayNumber: 22,
            title: 'PPS (After)',
            description: 'Post-Course PPS Form',
            isLocked: true,
            isCompleted: false,
          ),
        );
        changed = true;
      }
      if (changed) {
        await _prepService.updateModuleState(_userId!, userModules);
      }
    }

    // Check if a reset is needed due to a future startDate
    if (start != null && start.isAfter(DateTime.now())) {
      await _resetCourse(userModules);
      userStartDate = null; // No active course after reset
      didReset = true;      // Mark that a reset occurred
      setState(() {
        _hasUserClickedStart = false; // Show "Start Course" button again
      });
    } else {
      userStartDate = start;
    }

    // Apply locking logic:
    // - If a reset occurred, lock all modules including Day 0.
    // - Otherwise, preserve Day 0's lock state.
    if (didReset) {
      userModules = userModules.map((m) => m.copyWith(isLocked: true)).toList();
    } else {
      userModules = userModules.map((m) {
        if (m.dayNumber == 0) {
          return m; // Preserve Day 0 state if not resetting
        }
        return m.copyWith(isLocked: true);
      }).toList();
    }

    // Apply daily logic for further adjustments (skips altering Day 0)
    userModules = _applyDailyLocking(userModules);

    setState(() {
      allModules = userModules;
      _isLoading = false;
    });

    // If startDate is in the future => reset
    if (start != null && start.isAfter(DateTime.now())) {
      await _resetCourse(userModules);
      userStartDate = null; // no active course
      setState(() {
        _hasUserClickedStart = false; // show Start Course again
      });
    } else {
      // Might be valid date or null
      userStartDate = start;
    }

    // Lock everything except Day 0 (temp)
    userModules = userModules.map((m) {
      if (m.dayNumber == 0) {
        return m; // Preserve Day 0 state
      }
      return m.copyWith(isLocked: true);
    }).toList();

    // Apply daily logic
    userModules = _applyDailyLocking(userModules);

    setState(() {
      allModules = userModules;
      _isLoading = false;
    });
  }

  /// Called if we see a future startDate => forcibly reset
  Future<void> _resetCourse(List<DayModule> userModules) async {
    // Lock all modules including Day 0 and reset completion status
    userModules = userModules
        .map((m) => m.copyWith(isLocked: true, isCompleted: false))
        .toList();

    await _prepService.resetStartDateAndModules(_userId!, userModules);
  }


  /// Create day 0..22 (PPS Before => 0, main => 1..21, PPS After => 22)
  List<DayModule> _generateDefaultModules() {
    List<DayModule> modules = [];

    // Day 0 => PPS (Before)
    modules.add(
      DayModule(
        dayNumber: 0,
        title: 'PPS (Before)',
        description: 'Pre-Course PPS Form',
        isLocked: true,
        isCompleted: false,
      ),
    );

    // Day 1..21 => normal
    for (int i = 1; i <= 21; i++) {
      modules.add(
        DayModule(
          dayNumber: i,
          title: 'Module $i',
          description: 'Description for Module $i',
          isLocked: true,
          isCompleted: false,
        ),
      );
    }

    // Day 22 => PPS (After)
    modules.add(
      DayModule(
        dayNumber: 22,
        title: 'PPS (After)',
        description: 'Post-Course PPS Form',
        isLocked: true,
        isCompleted: false,
      ),
    );

    return modules;
  }

  /// Called when user taps "Start Course"
  /// - hides the button
  /// - if user hasn't done PPS(before), show that form
  /// - unlock day 0 so user can complete it
  Future<void> _startCourse() async {
    // Refresh data to ensure local state reflects the latest from Firestore
    await _loadUserData();
    setState(() {
      _hasUserClickedStart = true;
    });

    // Directly unlock Day 0 without automatically opening the PPS form
    final updated = allModules.map((m) {
      if (m.dayNumber == 0) {
        return m.copyWith(isLocked: false);
      }
      return m;
    }).toList();

    setState(() {
      allModules = updated;
    });
    await _prepService.updateModuleState(_userId!, updated);
  }

  /// Daily logic:
  ///  - Day 0 => unlocked if user tapped "Start Course" or it's completed
  ///  - Once day 0 completes => userStartDate = now
  ///  - Day N (1..21) locked if now < userStartDate + (N-1) days
  ///  - Day 22 => unlocked if now >= userStartDate + 21 days (no need to finish day 21)
  List<DayModule> _applyDailyLocking(List<DayModule> modules) {
    modules.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

    final now = DateTime.now();

    for (int i = 0; i < modules.length; i++) {
      final mod = modules[i];

      // If dayNumber=0 => keep it unlocked if already completed
      // or if user clicked Start. We'll just skip re-locking it
      if (mod.dayNumber == 0) {
        // do not forcibly lock it, so if user completed it once, remains unlocked
        continue;
      }

      // If dayNumber 1..21 => lock if date not reached
      if (mod.dayNumber >= 1 && mod.dayNumber <= 21) {
        bool locked = true;
        if (userStartDate != null) {
          final unlockDate = userStartDate!.add(Duration(days: mod.dayNumber - 1));
          locked = now.isBefore(unlockDate);
        }
        modules[i] = mod.copyWith(isLocked: locked);
      }

      // If dayNumber=22 => unlocked if now >= userStartDate+21 days
      // (no need for day21 completion)
      if (mod.dayNumber == 22) {
        bool locked = true;
        if (userStartDate != null) {
          final unlockDate = userStartDate!.add(Duration(days: 21));
          locked = now.isBefore(unlockDate);
        }
        modules[i] = mod.copyWith(isLocked: locked);
      }
    }

    return modules;
  }

  /// Mark dayNumber as completed => if day0 => userStartDate= now
  Future<void> _markModuleCompleted(int dayNumber) async {
    final idx = allModules.indexWhere((m) => m.dayNumber == dayNumber);
    if (idx == -1) return;

    allModules[idx] = allModules[idx].copyWith(isCompleted: true);

    // If user finished PPS(Before)= day0 => set official startDate
    if (dayNumber == 0) {
      final now = DateTime.now();
      userStartDate = now;
      await _prepService.setUserStartDate(_userId!, now);
    }

    // Re-lock/unlock with daily logic
    allModules = _applyDailyLocking(allModules);
    setState(() {});

    // Persist to Firestore
    await _prepService.updateModuleState(_userId!, allModules);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(0xFFB4347F);

    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Re-apply daily logic each build in case of time changes
    allModules = _applyDailyLocking(allModules);

    // Count main days (1..21) for the progress bar
    final mainModules = allModules.where((m) => m.dayNumber >= 1 && m.dayNumber <= 21).toList();
    final completedCount = mainModules.where((m) => m.isCompleted).length;
    final totalModules = 21;
    final progressValue = completedCount / totalModules;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: CustomScrollView(
          slivers: [
            // Hero header + "Start Course" button
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildHeroHeader(accentColor),
                  if (userStartDate == null && !_hasUserClickedStart)
                    Positioned(
                      bottom: -30,
                      right: 20,
                      child: ElevatedButton(
                        onPressed: _startCourse,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: accentColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          elevation: 4,
                        ),
                        child: Text(
                          'Start Course',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Body content: instructions + progress + modules list
            SliverToBoxAdapter(
              child: AnimatedPadding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  (userStartDate == null && !_hasUserClickedStart) ? 50 : 20,
                  20,
                  20,
                ),
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Intro text
                    Text(
                      "Prepare for Your Journey",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: accentColor),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Complete this 21-day course with exercises, tasks, and meditations "
                          "to thoroughly prepare yourself for your upcoming journey. This structured "
                          "approach ensures you are mentally, emotionally, and spiritually ready.",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 24),

                    // Show progress if user started
                    if (userStartDate != null) ...[
                      LinearProgressIndicator(
                        value: progressValue,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "$completedCount/$totalModules days completed",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      SizedBox(height: 20),
                    ],

                    // Modules list
                    AnimationLimiter(
                      child: Column(
                        children: List.generate(allModules.length, (index) {
                          final module = allModules[index];
                          final isLast = index == allModules.length - 1;
                          final heroTag = 'day-${module.dayNumber}-hero';

                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 300),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Vertical timeline & icon
                                    Container(
                                      width: 40,
                                      child: Column(
                                        children: [
                                          if (index > 0)
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
                                          if (!isLast)
                                            Container(
                                              width: 2,
                                              height: 20,
                                              color: Colors.grey[400],
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Day card
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
                                        child: GestureDetector(
                                          onTap: () => _handleModuleTap(module),
                                          child: DayModuleCard(module: module, heroTag: heroTag),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the top hero header with an image & back button
  Widget _buildHeroHeader(Color accentColor) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
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
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
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

  /// Handler for tapping a module (Day 0 => PPS Before, Day 22 => PPS After, or a normal day)
  Future<void> _handleModuleTap(DayModule module) async {
    if (module.isLocked) return; // do nothing if locked

    // If user taps PPS(Before) => show PPS form
    if (module.dayNumber == 0) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PPSFormScreen(
            isBeforeCourse: true,
            userId: _userId!,
          ),
        ),
      );
      // If they submitted => mark completed
      if (result == true) {
        await _markModuleCompleted(0);
      }
      return;
    }

    // If user taps PPS(After) => show PPS form (read-only if already done)
    if (module.dayNumber == 22) {
      final ppsResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PPSFormScreen(
            isBeforeCourse: false,
            userId: _userId!,
          ),
        ),
      );
      // If user submitted => mark completed
      if (ppsResult == true) {
        setState(() {
          _hasDoneAfterPPS = true;
        });
        await _markModuleCompleted(22);
      }
      return;
    }

    // Otherwise => normal day detail
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DayDetailScreen(
          dayNumber: module.dayNumber,
          isDayCompleted: module.isCompleted,
        ),
      ),
    );
    if (result == true) {
      await _markModuleCompleted(module.dayNumber);
    }
  }
}
