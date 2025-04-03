import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/daymodule.dart';
import '../services/integration_course_service.dart';
import '../services/notification_service.dart';

class IntegrationProvider extends ChangeNotifier {
  final String userId;
  final IntegrationCourseService integrationService;
  final NotificationService _notificationService = NotificationService();

  bool isLoading = false;
  String? errorMessage;

  DateTime? userStartDate;
  List<DayModule> allModules = [];
  bool hasUserClickedStart = false;

  IntegrationProvider({
    required this.userId,
    required this.integrationService,
  });

  Future<void> loadData() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      print('[IntegrationProvider] Loading data for user: $userId');

      // First, fetch the current start date from Firebase.
      final currentStartDate = await _fetchCurrentStartDate();
      userStartDate = currentStartDate;
      hasUserClickedStart = currentStartDate != null;

      // Then load the modules.
      final userData = await integrationService.getUserIntegrationData(userId);
      List<DayModule> userModules = [];

      if (userData != null && userData['modules'] is List) {
        for (var m in userData['modules']) {
          userModules.add(DayModule.fromMap(m));
        }
      }

      if (userModules.isEmpty) {
        userModules = _generateDefaultModules();
        await integrationService.updateModuleState(userId, userModules);
        print('[IntegrationProvider] No existing modules found; generated default modules.');
      }

      // Apply locking based on the current start date.
      userModules = _applyDailyLocking(userModules);
      allModules = userModules;

      print('[IntegrationProvider] Finished loading data. Modules count: ${allModules.length}');
    } catch (e) {
      errorMessage = e.toString();
      print('[IntegrationProvider] loadData error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<DateTime?> _fetchCurrentStartDate() async {
    try {
      final userData = await integrationService.getUserIntegrationData(userId);
      if (userData != null && userData['startDate'] != null) {
        return (userData['startDate'] as Timestamp).toDate();
      }
      return null;
    } catch (e) {
      print('[IntegrationProvider] Error fetching start date: $e');
      return null;
    }
  }

  Future<void> setUserStartDate(DateTime startDate) async {
    try {
      print('[IntegrationProvider] Setting user start date to: $startDate');

      userStartDate = startDate;
      hasUserClickedStart = true;
      await integrationService.setUserStartDate(userId, startDate);

      final freshModules = _generateDefaultModules();
      allModules = _applyDailyLocking(freshModules);
      await integrationService.updateModuleState(userId, freshModules);

      // Schedule notifications for the first 3 days /////// exmaple not working so far
      for (int i = 1; i <= 3; i++) {
        final dayUnlockDate = startDate.add(Duration(days: i - 1));
        print('[IntegrationProvider] Scheduling notification for Day $i at $dayUnlockDate');
        await _notificationService.scheduleDailyNotification(
          id: i + 1000,
          title: "Integration Journey",
          body: "Day $i of your integration practice is ready. Take time to reflect and grow.",
          hour: 10,
          minute: 0,
          second: 0,
          startDate: dayUnlockDate,
        );
      }

      // Update progress in Firebase.
      await _updateProgress();

      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to set start date: $e';
      print('[IntegrationProvider] setUserStartDate error: $e');
      notifyListeners();
      throw e;
    }
  }

  Future<void> startCourse() async {
    hasUserClickedStart = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      // Example: start from today's date at 6 AM To be implemented later
      userStartDate = DateTime(now.year, now.month, now.day, 6, 0, 0);
      print('[IntegrationProvider] Starting course, userStartDate = $userStartDate');

      await integrationService.setUserStartDate(userId, userStartDate!);

      final freshModules = _generateDefaultModules();
      allModules = _applyDailyLocking(freshModules);
      await integrationService.updateModuleState(userId, freshModules);

      // Update progress after starting the course.
      await _updateProgress();

      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to start integration course: $e';
      print('[IntegrationProvider] startCourse error: $e');
      notifyListeners();
    }
  }

  /// Mark the day [dayNumber] as completed, and schedule a notification only for the next day.
  Future<void> markModuleCompleted(int dayNumber) async {
    print('[IntegrationProvider] markModuleCompleted called for Day $dayNumber');

    final idx = allModules.indexWhere((m) => m.dayNumber == dayNumber);
    if (idx == -1) {
      print('[IntegrationProvider] Day $dayNumber not found in modules. Aborting completion update.');
      return;
    }

    // Mark the current day completed
    allModules[idx] = allModules[idx].copyWith(isCompleted: true);
    allModules = _applyDailyLocking(allModules);
    notifyListeners();

    try {
      // Update the module state in Firestore.
      await integrationService.updateModuleState(userId, allModules);

      // Update the specific module completion in Firestore.
      await integrationService.updateModuleCompletion(
        userId,
        dayNumber,
        true,
        {},
      );

      // Update progress after marking a module as completed.
      await _updateProgress();

      // Cancel any existing notification for this day
      final currentDayNotifId = dayNumber + 1000;
      await _notificationService.cancelNotification(currentDayNotifId);
      print('[IntegrationProvider] Canceled notification ID = $currentDayNotifId for Day $dayNumber');


      // Now schedule a notification only for the next day
      final nextDayNumber = dayNumber + 1;
      if (nextDayNumber <= 21) {
        final nextDayModule = allModules.firstWhere(
              (m) => m.dayNumber == nextDayNumber,
          orElse: () => DayModule(
            dayNumber: nextDayNumber,
            title: 'Integration Day $nextDayNumber',
            description: 'Daily Integration Practice',
            isLocked: true,
            isCompleted: false,
          ),
        );

        // If the next day is not completed, schedule a single notification for that day.
        if (!nextDayModule.isCompleted) {
          final dayUnlockDate = userStartDate!.add(Duration(days: nextDayNumber - 1));
          final nextDayNotifId = nextDayNumber + 1000;

          print('[IntegrationProvider] Scheduling notification for Day $nextDayNumber at $dayUnlockDate, notification ID = $nextDayNotifId');

          await _notificationService.scheduleDailyNotification(
            id: nextDayNotifId,
            title: "Integration Journey",
            body: "Day $nextDayNumber of your integration practice is ready. Take time to reflect and grow.",
            hour: 10,
            minute: 0,
            second: 0,
            startDate: dayUnlockDate,
          );
        } else {
          print('[IntegrationProvider] Next day ($nextDayNumber) is already completed; no new notification scheduled.');
        }
      }

    } catch (e) {
      errorMessage = 'Failed to update module completion: $e';
      print('[IntegrationProvider] markModuleCompleted error: $e');
      notifyListeners();
    }
  }

  // New helper method to update progress value in Firebase.
  Future<void> _updateProgress() async {
    try {
      final completedCount = allModules.where((m) => m.isCompleted).length;
      final totalModules = allModules.length;
      final progress = totalModules > 0 ? (completedCount / totalModules) * 100 : 0;

      print('[IntegrationProvider] _updateProgress -> completed: $completedCount / $totalModules ($progress%)');

      await integrationService.firestore
          .collection('integration_progress')
          .doc(userId)
          .set({
        'progress': progress,
        'completedCount': completedCount,
        'totalModules': totalModules,
        'lastUpdated': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('[IntegrationProvider] Error updating progress: $e');
    }
  }

  List<DayModule> _applyDailyLocking(List<DayModule> modules) {
    if (userStartDate == null) {
      // If userStartDate is null, lock everything.
      print('[IntegrationProvider] _applyDailyLocking -> userStartDate is null, all locked.');
      return modules.map((m) => m.copyWith(isLocked: true)).toList();
    }

    modules.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    final now = DateTime.now();

    // Normalize times to start of day for comparison.
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final normalizedStart = DateTime(userStartDate!.year, userStartDate!.month, userStartDate!.day);

    // Calculate how many days have passed since user started.
    final daysSinceStart = normalizedNow.difference(normalizedStart).inDays;
    print('[IntegrationProvider] _applyDailyLocking -> daysSinceStart = $daysSinceStart');

    return modules.map((mod) {
      // Keep completed modules unlocked.
      if (mod.isCompleted) {
        return mod.copyWith(isLocked: false);
      }

      // Day 1 is unlocked if course has started.
      if (mod.dayNumber == 1) {
        return mod.copyWith(isLocked: false);
      }

      // For other days, unlock if enough days have passed since start.
      final shouldBeUnlocked = daysSinceStart >= (mod.dayNumber - 1);
      return mod.copyWith(isLocked: !shouldBeUnlocked);
    }).toList();
  }

  List<DayModule> _generateDefaultModules() {
    final modules = <DayModule>[];

    final integrationTitles = [
      'Grounding & Present Moment',
      'Emotional Processing',
      'Body Awareness',
      'Mindful Reflection',
      'Connection with Nature',
      'Social Integration',
      'Creative Expression',
      'Values & Purpose',
      'Shadow Work',
      'Relationships & Boundaries',
      'Daily Rituals',
      'Inner Child Work',
      'Spiritual Connection',
      'Physical Well-being',
      'Mental Clarity',
      'Community & Support',
      'Life Vision',
      'Integration in Daily Life',
      'Finding Balance',
      'Moving Forward',
      'Celebrating Growth'
    ];

    for (int i = 0; i < 21; i++) {
      modules.add(DayModule(
        dayNumber: i + 1,
        title: integrationTitles[i],
        description: 'Day ${i + 1} of your integration journey',
        isLocked: true,
        isCompleted: false,
      ));
    }
    print('[IntegrationProvider] _generateDefaultModules -> Generated 21 modules.');

    return modules;
  }
}
