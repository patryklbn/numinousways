import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/models/day_detail.dart';
import '/services/day_detail_service.dart';
import '/services/preparation_course_service.dart';

/// A provider to manage day detail state & Firestore logic for the preparation course.
class DayDetailProvider extends ChangeNotifier {
  final int dayNumber;
  final bool isDayCompletedInitially;

  DayDetailProvider({
    required this.dayNumber,
    required this.isDayCompletedInitially,
    required FirebaseFirestore firestoreInstance,
    required String userId,
  })  : _dayDetailService = DayDetailService(firestore: firestoreInstance),
        _prepService = PreparationCourseService(firestoreInstance),
        _userId = userId;

  final DayDetailService _dayDetailService;
  final PreparationCourseService _prepService;
  final String _userId;

  bool isLoading = false;
  DayDetail? dayDetail;
  bool get isDayCompleted => isDayCompletedInitially;

  /// Each key = task.title, value = bool for completion
  Map<String, bool> taskCompletion = {};

  Future<void> fetchData() async {
    isLoading = true;
    notifyListeners();

    try {
      // Fetch day detail.
      final details = await _dayDetailService.getDayDetail(dayNumber);
      dayDetail = details;

      // Load user specific data for tasks from the preparation modules.
      final userData = await _prepService.getUserPreparationData(_userId);
      Map<String, dynamic>? selectedModuleData;
      if (userData != null && userData['modules'] is List) {
        for (var m in userData['modules']) {
          if (m['dayNumber'] == dayNumber) {
            selectedModuleData = m;
            break;
          }
        }
      }

      // Initialize local checkbox states.
      final initialCompletion = <String, bool>{};
      if (details != null) {
        for (var task in details.tasks) {
          bool completed = isDayCompletedInitially;
          if (selectedModuleData != null && selectedModuleData['tasks'] != null) {
            final taskStates = Map<String, dynamic>.from(selectedModuleData['tasks']);
            completed = (taskStates[task.title] == true);
          }
          initialCompletion[task.title] = completed;
        }
      }
      taskCompletion = initialCompletion;
    } catch (e) {
      print('Error in fetchData: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  bool areAllTasksCompleted() {
    return taskCompletion.values.every((done) => done);
  }

  void toggleTaskCompletion(String taskTitle, bool value) {
    taskCompletion[taskTitle] = value;
    notifyListeners();
  }

  /// Called when user hits "Mark Day as Completed".
  Future<void> markDayAsCompleted() async {
    await _prepService.updateModuleCompletion(
      _userId,
      dayNumber,
      true,
      taskCompletion,
    );
    await _updateProgress();
  }


  Future<void> _updateProgress() async {
    try {
      // Fetch the user's preparation data to recalc progress.
      final userData = await _prepService.getUserPreparationData(_userId);
      int completedCount = 0;
      if (userData != null && userData['modules'] is List) {
        for (var m in userData['modules']) {
          if (m['isCompleted'] == true) {
            completedCount++;
          }
        }
      }
      const totalModules = 21;
      double progress = totalModules > 0 ? (completedCount / totalModules) * 100 : 0;
      await FirebaseFirestore.instance
          .collection('preparation_progress')
          .doc(_userId)
          .set({
        'progress': progress,
        'completedCount': completedCount,
        'totalModules': totalModules,
        'lastUpdated': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating preparation progress: $e');
    }
  }
}