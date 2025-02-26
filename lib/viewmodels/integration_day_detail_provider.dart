import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/models/day_detail.dart';
import '/models/daymodule.dart';
import '/services/integration_course_service.dart';
import '/services/integration_day_detail_service.dart';
import '/services/day_detail_service.dart'; // For fetching original day details

class IntegrationDayDetailProvider extends ChangeNotifier {
  final int dayNumber;
  final bool isDayCompletedInitially;
  final String _userId;

  final IntegrationDayDetailService _integrationDayDetailService;
  final IntegrationCourseService _integrationService;
  final DayDetailService _dayDetailService; // For original day details

  IntegrationDayDetailProvider({
    required this.dayNumber,
    required this.isDayCompletedInitially,
    required FirebaseFirestore firestoreInstance,
    required String userId,
  })  : _integrationDayDetailService =
  IntegrationDayDetailService(firestoreInstance),
        _integrationService = IntegrationCourseService(firestoreInstance),
        _dayDetailService = DayDetailService(firestoreInstance),
        _userId = userId;

  bool isLoading = false;
  DayDetail? dayDetail;
  bool get isDayCompleted => isDayCompletedInitially;

  /// Each key = task.title, value = bool for completion
  Map<String, bool> taskCompletion = {};

  Future<void> fetchData() async {
    isLoading = true;
    notifyListeners();

    try {
      DayDetail? details;

      // 1) Try to fetch integration day detail from integration_days collection.
      try {
        details = await _integrationDayDetailService.getDayDetail(dayNumber);
      } catch (e) {
        // If not found, fallback to the original days collection.
        print(
            'Integration day detail not found in integration_days, fetching original day detail: $e');
        details = await _dayDetailService.getDayDetail(dayNumber);
      }
      dayDetail = details;

      // 2) Load user-specific data for tasks from integration data.
      final userData = await _integrationService.getUserIntegrationData(_userId);
      Map<String, dynamic>? selectedModuleData;
      if (userData != null && userData['modules'] is List) {
        for (var m in userData['modules']) {
          if (m['dayNumber'] == dayNumber) {
            selectedModuleData = m;
            break;
          }
        }
      }

      // 3) Initialize local checkbox states.
      final initialCompletion = <String, bool>{};
      if (details != null) {
        for (var task in details.tasks) {
          bool completed = isDayCompletedInitially;
          if (selectedModuleData != null && selectedModuleData['tasks'] != null) {
            final taskStates =
            Map<String, dynamic>.from(selectedModuleData['tasks']);
            completed = (taskStates[task.title] == true);
          }
          initialCompletion[task.title] = completed;
        }
      }
      taskCompletion = initialCompletion;
    } catch (e) {
      print('Error in IntegrationDayDetailProvider.fetchData: $e');
      // Optionally, set an error state here for the UI.
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

  Future<void> markDayAsCompleted() async {
    try {
      await _integrationService.updateModuleCompletion(
        _userId,
        dayNumber,
        true, // pass "true" for day completed
        taskCompletion,
      );
    } catch (e) {
      print('Error marking integration day as completed: $e');
      rethrow;
    }
  }
}
