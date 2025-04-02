import 'package:flutter_test/flutter_test.dart';


class DayModule {
  final int dayNumber;
  final String title;
  final String description;
  final bool isLocked;
  final bool isCompleted;

  DayModule({
    required this.dayNumber,
    required this.title,
    required this.description,
    this.isLocked = false,
    this.isCompleted = false,
  });

  DayModule copyWith({
    int? dayNumber,
    String? title,
    String? description,
    bool? isLocked,
    bool? isCompleted,
  }) {
    return DayModule(
      dayNumber: dayNumber ?? this.dayNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      isLocked: isLocked ?? this.isLocked,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  static DayModule fromMap(Map<String, dynamic> map) {
    return DayModule(
      dayNumber: map['dayNumber'],
      title: map['title'],
      description: map['description'],
      isLocked: map['isLocked'] ?? false,
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}


class MockIntegrationCourseService {
  final firestore = null;

  Future<Map<String, dynamic>?> getUserIntegrationData(String userId) async {
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


class IntegrationProvider {
  final String userId;
  final MockIntegrationCourseService integrationService;
  final MockNotificationService _notificationService = MockNotificationService();

  bool isLoading = false;
  String? errorMessage;
  DateTime? userStartDate;
  List<DayModule> allModules = [];
  bool hasUserClickedStart = false;

  IntegrationProvider({
    required this.userId,
    required this.integrationService,
  });


  void setStartDate(DateTime date) {
    userStartDate = date;
    hasUserClickedStart = true;
  }


  void addModule(DayModule module) {
    allModules.add(module);
  }

  // Mark a module completed
  void markModuleCompleted(int dayNumber) {
    final index = allModules.indexWhere((m) => m.dayNumber == dayNumber);
    if (index >= 0) {
      allModules[index] = allModules[index].copyWith(isCompleted: true);
    }
  }
}

void main() {
  group('IntegrationProvider Basic Tests', () {
    test('Initial state should be correct', () {
      // Setup
      final provider = IntegrationProvider(
        userId: 'test-user',
        integrationService: MockIntegrationCourseService(),
      );

      // Verify initial state
      expect(provider.userId, equals('test-user'));
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.userStartDate, isNull);
      expect(provider.allModules, isEmpty);
      expect(provider.hasUserClickedStart, isFalse);
    });

    test('setStartDate() should update provider state', () {
      // Setup
      final provider = IntegrationProvider(
        userId: 'test-user',
        integrationService: MockIntegrationCourseService(),
      );

      // Execute
      final date = DateTime(2023, 1, 1);
      provider.setStartDate(date);

      // Verify
      expect(provider.userStartDate, equals(date));
      expect(provider.hasUserClickedStart, isTrue);
    });

    test('markModuleCompleted() should update module state', () {
      // Setup
      final provider = IntegrationProvider(
        userId: 'test-user',
        integrationService: MockIntegrationCourseService(),
      );

      // Add test modules
      provider.addModule(DayModule(
          dayNumber: 1,
          title: 'Day 1',
          description: 'Test description',
          isCompleted: false
      ));

      provider.addModule(DayModule(
          dayNumber: 2,
          title: 'Day 2',
          description: 'Test description',
          isCompleted: false
      ));

      // Execute
      provider.markModuleCompleted(1);

      // Verify
      expect(provider.allModules[0].isCompleted, isTrue);
      expect(provider.allModules[1].isCompleted, isFalse);
    });
  });
}