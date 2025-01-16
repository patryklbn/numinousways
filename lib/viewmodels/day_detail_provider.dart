import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/models/day_detail.dart';
import '/models/daymodule.dart';
import '/services/day_detail_service.dart';
import '/services/preparation_course_service.dart';

/// A provider to manage day detail state & Firestore logic.
class DayDetailProvider extends ChangeNotifier {
  final int dayNumber;
  final bool isDayCompletedInitially;

  /// You could also pass userId in constructor if you prefer
  /// or get it from a separate user provider as needed.

  DayDetailProvider({
    required this.dayNumber,
    required this.isDayCompletedInitially,
    required FirebaseFirestore firestoreInstance,
    required String userId,
  })  : _dayDetailService = DayDetailService(firestoreInstance),
        _prepService = PreparationCourseService(firestoreInstance),
        _userId = userId;

  final DayDetailService _dayDetailService;
  final PreparationCourseService _prepService;
  final String _userId;

  bool isLoading = false;
  DayDetail? dayDetail;
  bool get isDayCompleted => isDayCompletedInitially;
  // or you can store a mutable `bool _isDayCompleted` if you want to override it.

  /// Each key = task.title, value = bool for completion
  Map<String, bool> taskCompletion = {};

  /// Called typically once from outside (e.g. in initState of your screen).
  Future<void> fetchData() async {
    isLoading = true;
    notifyListeners();

    try {
      // 1) Fetch day detail
      final details = await _dayDetailService.getDayDetail(dayNumber);
      dayDetail = details;

      // 2) Load user-specific data for tasks from the preparation modules
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

      // 3) Initialize local checkbox states
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
      // handle error or do nothing
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
      true,         // pass "true" for day completed
      taskCompletion,
    );
  }
}
