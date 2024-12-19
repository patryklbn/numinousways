import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/models/daymodule.dart';
import '/widgets/preparation/daymodule_card.dart';
import 'day_detail_screen.dart';
import '/services/login_provider.dart';
import '/services/preparation_course_service.dart';

class PreparationCourseScreen extends StatefulWidget {
  @override
  _PreparationCourseScreenState createState() => _PreparationCourseScreenState();
}

class _PreparationCourseScreenState extends State<PreparationCourseScreen> {
  DateTime? userStartDate;
  List<DayModule> allModules = [];
  bool _isLoading = true;

  final PreparationCourseService _prepService = PreparationCourseService(FirebaseFirestore.instance);
  String? _userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userId = Provider.of<LoginProvider>(context, listen: false).userId;
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    // Load user-specific data
    final userData = await _prepService.getUserPreparationData(_userId!);

    DateTime? start;
    List<DayModule> userModules = [];

    if (userData != null) {
      if (userData['startDate'] != null) {
        start = (userData['startDate'] as Timestamp).toDate();
      }

      if (userData['modules'] != null && userData['modules'] is List) {
        for (var m in userData['modules']) {
          userModules.add(DayModule.fromMap(m));
        }
      }
    }

    // If modules are not initialized in firestore, initialize them
    if (userModules.isEmpty) {
      userModules = List.generate(21, (index) => DayModule(
        dayNumber: index + 1,
        title: 'Module ${index + 1}',
        description: 'Description for Module ${index + 1}',
        isLocked: true,
        isCompleted: false,
      ));
      // Save them to firestore
      await _prepService.updateModuleState(_userId!, userModules);
    }

    setState(() {
      userStartDate = start;
      allModules = userModules;
      _isLoading = false;
    });
  }

  Future<void> _startCourse() async {
    final now = DateTime.now();
    setState(() {
      userStartDate = now;
    });

    // Save to firestore
    await _prepService.setUserStartDate(_userId!, now);
    // Update locking state after start date is set
    _updateLockingState();
  }

  void _updateLockingState() {
    if (userStartDate == null) return;

    final updatedModules = allModules.map((module) {
      final unlockDate = userStartDate!.add(Duration(days: module.dayNumber - 1));
      bool isLocked = DateTime.now().isBefore(unlockDate);
      return module.copyWith(isLocked: isLocked);
    }).toList();

    setState(() {
      allModules = updatedModules;
    });

    // Update in firestore
    _prepService.updateModuleState(_userId!, allModules);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(0xFFB4347F);

    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Determine current locking state again if userStartDate is known
    _updateLockingState();

    final totalModules = allModules.length;
    final completedCount = allModules.where((m) => m.isCompleted).length;
    final progressValue = (userStartDate == null) ? 0.0 : completedCount / totalModules;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
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
                ),
                if (userStartDate == null)
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
          SliverToBoxAdapter(
            child: AnimatedPadding(
              padding: EdgeInsets.fromLTRB(20, userStartDate == null ? 50 : 20, 20, 20),
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Prepare for Your Journey",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: accentColor),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Complete this 21-day course with exercises, tasks, and meditations "
                        "to thoroughly prepare yourself for your upcoming journey. This structured "
                        "approach ensures you are mentally, emotionally, and spiritually ready.",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Colors.black87, height: 1.5),
                  ),
                  SizedBox(height: 24),
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
                                  Container(
                                    width: 40,
                                    child: Column(
                                      children: [
                                        if (index > 0) Container(width: 2, height: 20, color: Colors.grey[400]),
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
                                        if (!isLast) Container(width: 2, height: 20, color: Colors.grey[400]),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
                                      child: GestureDetector(
                                        onTap: () async {
                                          if (!module.isLocked && userStartDate != null) {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => DayDetailScreen(
                                                  dayNumber: module.dayNumber,
                                                  isDayCompleted: module.isCompleted,
                                                ),
                                              ),
                                            );

                                            // If the result is true, mark the module as completed in state and firestore
                                            if (result == true) {
                                              final idx = allModules.indexWhere((m) => m.dayNumber == module.dayNumber);
                                              if (idx != -1) {
                                                final updatedModule = allModules[idx].copyWith(isCompleted: true);
                                                allModules[idx] = updatedModule;
                                                setState(() {});
                                                // Update Firestore
                                                await _prepService.updateModuleCompletion(
                                                    _userId!,
                                                    module.dayNumber,
                                                    true,
                                                    {} // tasks handled in DayDetailScreen
                                                );
                                              }
                                            }
                                          }
                                        },
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
    );
  }
}
