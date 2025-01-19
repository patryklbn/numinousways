import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/daymodule.dart';
import '../services/preparation_course_service.dart';
import '../services/notification_service.dart';

class PreparationProvider extends ChangeNotifier {
  final String userId;
  final PreparationCourseService prepService;
  final NotificationService _notificationService = NotificationService();

  bool isLoading = false;
  String? errorMessage;

  DateTime? userStartDate;
  List<DayModule> allModules = [];
  bool hasUserClickedStart = false;

  PreparationProvider({
    required this.userId,
    required this.prepService,
  });

  Future<void> loadData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final userData = await prepService.getUserPreparationData(userId);

      List<DayModule> userModules = [];
      DateTime? start;
      if (userData != null) {
        if (userData['startDate'] != null) {
          start = (userData['startDate'] as Timestamp).toDate();
        }
        if (userData['modules'] is List) {
          for (var m in userData['modules']) {
            userModules.add(DayModule.fromMap(m));
          }
        }
      }

      if (userModules.isEmpty) {
        userModules = _generateDefaultModules();
        await prepService.updateModuleState(userId, userModules);
      } else {
        bool changed = false;
        if (!userModules.any((m) => m.dayNumber == 0)) {
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
        if (!userModules.any((m) => m.dayNumber == 22)) {
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

      if (userData?['startDate'] != null) {
        final start = (userData!['startDate'] as Timestamp).toDate();
        if (start.isAfter(DateTime.now())) {
          await _resetCourse(userModules);
          await _reloadAfterReset();
          userStartDate = null;
          hasUserClickedStart = false;
        } else {
          userStartDate = start;
        }
      } else {
        userStartDate = null;
      }

      // Unlock Day 0 if course has started; lock others initially
      userModules = userModules.map((m) {
        if (m.dayNumber == 0 && userStartDate != null) {
          return m.copyWith(isLocked: false);
        }
        return m.copyWith(isLocked: true);
      }).toList();

      userModules = _applyDailyLocking(userModules);
      allModules = userModules;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _reloadAfterReset() async {
    final newData = await prepService.getUserPreparationData(userId);
    List<DayModule> newModules = [];
    if (newData != null && newData['modules'] is List) {
      for (var m in newData['modules']) {
        newModules.add(DayModule.fromMap(m));
      }
    }
    allModules = newModules;
  }

  Future<void> startCourse() async {
    hasUserClickedStart = true;
    notifyListeners();

    if (allModules.isEmpty) {
      await loadData();
    }

    final freshModules = _generateDefaultModules();
    allModules = freshModules;
    await prepService.updateModuleState(userId, freshModules);

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

      final now = DateTime.now();
      userStartDate = DateTime(now.year, now.month, now.day, 6, 0, 0);
      await prepService.setUserStartDate(userId, userStartDate!);

      final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
      try {
        await userDoc.collection('ppsForms').doc('before').delete();
      } catch (_) {}
      try {
        await userDoc.collection('ppsForms').doc('after').delete();
      } catch (_) {}

      // Notifications will be scheduled after Day 0 completion.
    } catch (e) {
      errorMessage = 'Failed to start course: $e';
      notifyListeners();
    }
  }

  Future<void> _resetCourse(List<DayModule> userModules) async {
    final resetModules = userModules
        .map((m) => m.copyWith(isLocked: true, isCompleted: false))
        .toList();

    try {
      await prepService.resetStartDateAndModules(userId, resetModules);
      await _notificationService.cancelAllNotifications();
    } catch (e) {
      errorMessage = 'Failed to reset course: $e';
      notifyListeners();
    }
  }

  Future<void> markModuleCompleted(int dayNumber) async {
    final idx = allModules.indexWhere((m) => m.dayNumber == dayNumber);
    if (idx == -1) return;

    allModules[idx] = allModules[idx].copyWith(isCompleted: true);
    allModules = _applyDailyLocking(allModules);
    notifyListeners();

    try {
      await prepService.updateModuleState(userId, allModules);

      final now = DateTime.now();
      if (dayNumber == 0) {
        for (int i = 1; i <= 21; i++) {
          final module = allModules.firstWhere(
                (m) => m.dayNumber == i,
            orElse: () => DayModule(
              dayNumber: i,
              title: 'Module $i',
              description: 'Auto fallback',
              isLocked: true,
              isCompleted: false,
            ),
          );
          if (!module.isCompleted) {
            final dayUnlockDate = userStartDate!.add(Duration(days: i - 1));
            await _notificationService.scheduleDailyNotification(
              id: i,
              title: "Daily Retreat Reminder",
              body: "Day $i is available! Complete your daily tasks today.",
              hour: 18,
              minute: 30,
              second: 0,
              startDate: dayUnlockDate,
            );
          }
        }
      }

      // Cancel notification for the completed day.
      await _notificationService.cancelNotification(dayNumber);
      print("[PreparationProvider] Notification for Day $dayNumber canceled.");
    } catch (e) {
      errorMessage = 'Failed to update module completion: $e';
      notifyListeners();
    }
  }

  List<DayModule> _applyDailyLocking(List<DayModule> modules) {
    modules.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    final now = DateTime.now();

    // Safely retrieve Day 0
    DayModule? day0;
    try {
      day0 = modules.firstWhere((m) => m.dayNumber == 0);
    } catch (e) {
      day0 = null;
    }
    final day0Completed = day0 != null && day0.isCompleted;

    for (int i = 0; i < modules.length; i++) {
      final mod = modules[i];

      // *** Day 0 handling ***
      if (mod.dayNumber == 0) {
        if (userStartDate == null) {
          modules[i] = mod.copyWith(isLocked: true);
        } else if (mod.isCompleted) {
          modules[i] = mod.copyWith(isLocked: false);
        }
        continue;
      }

      // *** Days 1..21 locking logic ***
      if (mod.dayNumber >= 1 && mod.dayNumber <= 21) {
        bool locked = true;
        // Only unlock further days if Day 0 is completed
        if (userStartDate != null && day0Completed) {
          final unlockDate = userStartDate!.add(Duration(days: mod.dayNumber - 1));
          locked = now.isBefore(unlockDate);
        }
        modules[i] = mod.copyWith(isLocked: locked);
      }
      // *** Day 22 locking logic ***
      else if (mod.dayNumber == 22) {
        bool locked = true;
        if (userStartDate != null && day0Completed) {
          final unlockDate = userStartDate!.add(const Duration(days: 21));
          locked = now.isBefore(unlockDate);
        }
        modules[i] = mod.copyWith(isLocked: locked);
      }
    }
    return modules;
  }

  List<DayModule> _generateDefaultModules() {
    final modules = <DayModule>[];

    modules.add(DayModule(
      dayNumber: 0,
      title: 'PPS (Before)',
      description: 'Pre-Course PPS Form',
      isLocked: true,
      isCompleted: false,
    ));

    for (int i = 1; i <= 21; i++) {
      modules.add(DayModule(
        dayNumber: i,
        title: 'Module $i',
        description: 'Description for Module $i',
        isLocked: true,
        isCompleted: false,
      ));
    }

    modules.add(DayModule(
      dayNumber: 22,
      title: 'PPS (After)',
      description: 'Post-Course PPS Form',
      isLocked: true,
      isCompleted: false,
    ));

    return modules;
  }
}
