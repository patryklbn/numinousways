import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/daymodule.dart';
import '../services/preparation_course_service.dart';

/// A ChangeNotifier that holds & manages the 21-day preparation course data
/// for a single user. Moves logic from PreparationCourseScreen to a central place.
class PreparationProvider extends ChangeNotifier {
  final String userId;
  final PreparationCourseService prepService;

  /// Basic states
  bool isLoading = false;
  String? errorMessage;

  /// Core data
  DateTime? userStartDate;
  List<DayModule> allModules = [];

  /// Track whether the user has tapped "Start Course" in the current session
  bool hasUserClickedStart = false;

  PreparationProvider({
    required this.userId,
    required this.prepService,
  });

  /// Initialize or refresh data. Call this from your screen’s `initState()` or pull-to-refresh.
  Future<void> loadData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final userData = await prepService.getUserPreparationData(userId);
      // Default empty modules if none exist
      List<DayModule> userModules = [];
      DateTime? start;

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

      // Initialize modules if empty
      if (userModules.isEmpty) {
        userModules = _generateDefaultModules();
        await prepService.updateModuleState(userId, userModules);
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
          await prepService.updateModuleState(userId, userModules);
        }
      }

      // If start date is in the future, reset
      if (start != null && start.isAfter(DateTime.now())) {
        await _resetCourse(userModules);
        userStartDate = null;
        hasUserClickedStart = false;
      } else {
        userStartDate = start;
      }

      // Lock all modules initially (except day 0 if completed)
      userModules = userModules.map((m) {
        if (m.dayNumber == 0) {
          // do not forcibly lock Day 0 if already completed
          return m;
        }
        return m.copyWith(isLocked: true);
      }).toList();

      // Then apply daily logic
      userModules = _applyDailyLocking(userModules);

      allModules = userModules;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Called when the user taps the "Start Course" button.
  /// We unlock Day 0, persist to Firestore, and hide that button in the UI.
  Future<void> startCourse() async {
    hasUserClickedStart = true;
    notifyListeners();

    // Make sure we have fresh modules
    if (allModules.isEmpty) {
      await loadData();
    }

    // Unlock day 0
    final updated = allModules.map((m) {
      if (m.dayNumber == 0) {
        return m.copyWith(isLocked: false);
      }
      return m;
    }).toList();

    allModules = updated;
    notifyListeners();

    try {
      await prepService.updateModuleState(userId, updated);
    } catch (e) {
      errorMessage = 'Failed to start course: $e';
      notifyListeners();
    }
  }

  /// If we discover a future startDate, we reset all modules & remove startDate.
  Future<void> _resetCourse(List<DayModule> userModules) async {
    // Lock & reset modules
    userModules = userModules.map(
          (m) => m.copyWith(isLocked: true, isCompleted: false),
    ).toList();

    try {
      await prepService.resetStartDateAndModules(userId, userModules);
    } catch (e) {
      errorMessage = 'Failed to reset course: $e';
      notifyListeners();
    }
  }

  /// Mark dayNumber as completed => if day0 => set userStartDate=now
  Future<void> markModuleCompleted(int dayNumber) async {
    final idx = allModules.indexWhere((m) => m.dayNumber == dayNumber);
    if (idx == -1) return;

    allModules[idx] = allModules[idx].copyWith(isCompleted: true);

    // If user finished PPS(Before)= day0 => set official startDate to now
    if (dayNumber == 0) {
      final now = DateTime.now();
      userStartDate = now;
      notifyListeners(); // so the daily logic re-applies

      try {
        await prepService.setUserStartDate(userId, now);
      } catch (e) {
        errorMessage = 'Failed to set start date: $e';
        notifyListeners();
      }
    }

    // Re-lock/unlock with daily logic
    allModules = _applyDailyLocking(allModules);
    notifyListeners();

    // Persist to Firestore
    try {
      await prepService.updateModuleState(userId, allModules);
    } catch (e) {
      errorMessage = 'Failed to update module completion: $e';
      notifyListeners();
    }
  }

  /// Applies the daily logic to lock or unlock modules based on userStartDate
  List<DayModule> _applyDailyLocking(List<DayModule> modules) {
    modules.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    final now = DateTime.now();

    for (int i = 0; i < modules.length; i++) {
      final mod = modules[i];

      if (mod.dayNumber == 0) {
        // if day0 is completed or user clicked start, keep it unlocked
        continue;
      }

      // Day 1..21 => locked if now < userStartDate + (N-1) days
      if (mod.dayNumber >= 1 && mod.dayNumber <= 21) {
        bool locked = true;
        if (userStartDate != null) {
          final unlockDate = userStartDate!.add(Duration(days: mod.dayNumber - 1));
          locked = now.isBefore(unlockDate);
        }
        modules[i] = mod.copyWith(isLocked: locked);
      }

      // Day 22 => unlocked if now >= userStartDate + 21 days
      if (mod.dayNumber == 22) {
        bool locked = true;
        if (userStartDate != null) {
          final unlockDate = userStartDate!.add(const Duration(days: 21));
          locked = now.isBefore(unlockDate);
        }
        modules[i] = mod.copyWith(isLocked: locked);
      }
    }

    return modules;
  }

  /// A helper that returns (or creates) the default modules from Day0..Day22
  List<DayModule> _generateDefaultModules() {
    List<DayModule> modules = [];

    modules.add(
      DayModule(
        dayNumber: 0,
        title: 'PPS (Before)',
        description: 'Pre-Course PPS Form',
        isLocked: true,
        isCompleted: false,
      ),
    );

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
}
