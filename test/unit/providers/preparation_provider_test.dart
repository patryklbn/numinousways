import 'package:flutter_test/flutter_test.dart';
import 'package:numinous_ways/models/daymodule.dart';

// Simple mock for the service
class MockPreparationCourseService {
  final firestore = null;

  Future<Map<String, dynamic>?> getUserPreparationData(String userId) async {
    return null;
  }

  Future<void> updateModuleState(String userId, List<DayModule> modules) async {}

  Future<void> setUserStartDate(String userId, DateTime startDate) async {}

  Future<void> updateModuleCompletion(
      String userId,
      int dayNumber,
      bool isCompleted,
      Map<String, bool> taskCompletion,
      ) async {}

  Future<void> resetStartDateAndModules(String userId, List<DayModule> modules) async {}

  Future<bool> hasPPSForm(String userId, bool isBeforeCourse) async {
    return false;
  }
}

// Mock notification service
class MockNotificationService {
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required int second,
    required DateTime startDate,
  }) async {}

  Future<void> cancelNotification(int id) async {}
}

// Simplified version of PreparationProvider for testing
class PreparationProvider {
  final String userId;
  final MockPreparationCourseService preparationService;
  final MockNotificationService _notificationService = MockNotificationService();

  bool isLoading = false;
  String? errorMessage;
  DateTime? userStartDate;
  List<DayModule> allModules = [];
  bool hasUserClickedStart = false;
  bool hasCompletedBeforeSurvey = false;
  bool hasCompletedAfterSurvey = false;

  PreparationProvider({
    required this.userId,
    required this.preparationService,
  });

  // Set start date
  void setStartDate(DateTime date) {
    userStartDate = date;
    hasUserClickedStart = true;
  }

  // Reset start date
  void resetStartDate() {
    userStartDate = null;
    hasUserClickedStart = false;
    // Reset module completion status
    for (int i = 0; i < allModules.length; i++) {
      allModules[i] = allModules[i].copyWith(
        isCompleted: false,
        isLocked: i != 0, // Only first module is unlocked
      );
    }
  }

  // Add a module for testing
  void addModule(DayModule module) {
    allModules.add(module);
  }

  // Mark a module completed
  void markModuleCompleted(int dayNumber) {
    final index = allModules.indexWhere((m) => m.dayNumber == dayNumber);
    if (index >= 0) {
      allModules[index] = allModules[index].copyWith(isCompleted: true);

      // Unlock next module if available
      if (index < allModules.length - 1) {
        allModules[index + 1] = allModules[index + 1].copyWith(isLocked: false);
      }
    }
  }

  // Mark survey completion
  void setBeforeSurveyCompleted(bool isCompleted) {
    hasCompletedBeforeSurvey = isCompleted;
  }

  void setAfterSurveyCompleted(bool isCompleted) {
    hasCompletedAfterSurvey = isCompleted;
  }

  // Get active module
  DayModule? getActiveModule() {
    // Return the first uncompleted unlocked module
    return allModules.firstWhere(
          (module) => !module.isCompleted && !module.isLocked,
      orElse: () => allModules.last,
    );
  }
}

void main() {
  group('PreparationProvider Basic Tests', () {
    test('Initial state should be correct', () {
      // Setup
      final provider = PreparationProvider(
        userId: 'test-user',
        preparationService: MockPreparationCourseService(),
      );

      // Verify initial state
      expect(provider.userId, equals('test-user'));
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.userStartDate, isNull);
      expect(provider.allModules, isEmpty);
      expect(provider.hasUserClickedStart, isFalse);
      expect(provider.hasCompletedBeforeSurvey, isFalse);
      expect(provider.hasCompletedAfterSurvey, isFalse);
    });

    test('setStartDate() should update provider state', () {
      // Setup
      final provider = PreparationProvider(
        userId: 'test-user',
        preparationService: MockPreparationCourseService(),
      );

      // Execute
      final date = DateTime(2023, 1, 1);
      provider.setStartDate(date);

      // Verify
      expect(provider.userStartDate, equals(date));
      expect(provider.hasUserClickedStart, isTrue);
    });

    test('resetStartDate() should clear start date and reset modules', () {
      // Setup
      final provider = PreparationProvider(
        userId: 'test-user',
        preparationService: MockPreparationCourseService(),
      );

      // Add modules and set initial state
      provider.addModule(DayModule(
          dayNumber: 1,
          title: 'Day 1',
          description: 'Test description',
          isLocked: false,
          isCompleted: true
      ));

      provider.addModule(DayModule(
          dayNumber: 2,
          title: 'Day 2',
          description: 'Test description',
          isLocked: false,
          isCompleted: false
      ));

      final date = DateTime(2023, 1, 1);
      provider.setStartDate(date);

      // Execute
      provider.resetStartDate();

      // Verify
      expect(provider.userStartDate, isNull);
      expect(provider.hasUserClickedStart, isFalse);
      expect(provider.allModules[0].isCompleted, isFalse);
      expect(provider.allModules[0].isLocked, isFalse); // First module unlocked
      expect(provider.allModules[1].isLocked, isTrue); // Second module locked
    });

    test('markModuleCompleted() should update module state and unlock next module', () {
      // Setup
      final provider = PreparationProvider(
        userId: 'test-user',
        preparationService: MockPreparationCourseService(),
      );

      // Add some test modules
      provider.addModule(DayModule(
          dayNumber: 1,
          title: 'Day 1',
          description: 'Test description',
          isLocked: false,
          isCompleted: false
      ));

      provider.addModule(DayModule(
          dayNumber: 2,
          title: 'Day 2',
          description: 'Test description',
          isLocked: true,
          isCompleted: false
      ));

      // Execute
      provider.markModuleCompleted(1);

      // Verify
      expect(provider.allModules[0].isCompleted, isTrue);
      expect(provider.allModules[1].isLocked, isFalse); // Should unlock next module
    });

    test('setBeforeSurveyCompleted() should update survey completion state', () {
      // Setup
      final provider = PreparationProvider(
        userId: 'test-user',
        preparationService: MockPreparationCourseService(),
      );

      // Execute
      provider.setBeforeSurveyCompleted(true);

      // Verify
      expect(provider.hasCompletedBeforeSurvey, isTrue);
    });

    test('setAfterSurveyCompleted() should update survey completion state', () {
      // Setup
      final provider = PreparationProvider(
        userId: 'test-user',
        preparationService: MockPreparationCourseService(),
      );

      // Execute
      provider.setAfterSurveyCompleted(true);

      // Verify
      expect(provider.hasCompletedAfterSurvey, isTrue);
    });

    test('getActiveModule() should return first unlocked incomplete module', () {
      // Setup
      final provider = PreparationProvider(
        userId: 'test-user',
        preparationService: MockPreparationCourseService(),
      );

      // Add some test modules
      provider.addModule(DayModule(
          dayNumber: 1,
          title: 'Day 1',
          description: 'Test description',
          isLocked: false,
          isCompleted: true
      ));

      provider.addModule(DayModule(
          dayNumber: 2,
          title: 'Day 2',
          description: 'Test description',
          isLocked: false,
          isCompleted: false
      ));

      provider.addModule(DayModule(
          dayNumber: 3,
          title: 'Day 3',
          description: 'Test description',
          isLocked: true,
          isCompleted: false
      ));

      // Execute
      final activeModule = provider.getActiveModule();

      // Verify
      expect(activeModule, isNotNull);
      expect(activeModule!.dayNumber, equals(2));
    });

    test('getActiveModule() should return last module if all completed', () {
      // Setup
      final provider = PreparationProvider(
        userId: 'test-user',
        preparationService: MockPreparationCourseService(),
      );

      // Add some test modules (all completed)
      provider.addModule(DayModule(
          dayNumber: 1,
          title: 'Day 1',
          description: 'Test description',
          isLocked: false,
          isCompleted: true
      ));

      provider.addModule(DayModule(
          dayNumber: 2,
          title: 'Day 2',
          description: 'Test description',
          isLocked: false,
          isCompleted: true
      ));

      // Execute
      final activeModule = provider.getActiveModule();

      // Verify
      expect(activeModule, isNotNull);
      expect(activeModule!.dayNumber, equals(2)); // Should return last module
    });
  });
}