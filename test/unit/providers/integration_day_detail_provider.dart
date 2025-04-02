import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:numinous_ways/viewmodels//integration_day_detail_provider.dart';

void main() {
  group('IntegrationDayDetailProvider Basic Tests', () {
    test('Initial state should be correct', () {
      // Setup
      final fakeFirestore = FakeFirebaseFirestore();
      final provider = IntegrationDayDetailProvider(
        dayNumber: 3,
        isDayCompletedInitially: false,
        firestoreInstance: fakeFirestore,
        userId: 'test-user-123',
      );

      // Verify initial state
      expect(provider.dayNumber, equals(3));
      expect(provider.isDayCompleted, equals(false));
      expect(provider.isLoading, equals(false));
      expect(provider.dayDetail, isNull);
      expect(provider.taskCompletion, isEmpty);
    });

    test('areAllTasksCompleted() should check all task completion status', () {
      // Setup
      final fakeFirestore = FakeFirebaseFirestore();
      final provider = IntegrationDayDetailProvider(
        dayNumber: 3,
        isDayCompletedInitially: false,
        firestoreInstance: fakeFirestore,
        userId: 'test-user-123',
      );

      // All false
      provider.taskCompletion = {
        'Task 1': false,
        'Task 2': false,
      };
      expect(provider.areAllTasksCompleted(), equals(false));

      // Mixed
      provider.taskCompletion = {
        'Task 1': true,
        'Task 2': false,
      };
      expect(provider.areAllTasksCompleted(), equals(false));

      // All true
      provider.taskCompletion = {
        'Task 1': true,
        'Task 2': true,
      };
      expect(provider.areAllTasksCompleted(), equals(true));

      // Empty - should return true (vacuously true)
      provider.taskCompletion = {};
      expect(provider.areAllTasksCompleted(), equals(true));
    });

    test('toggleTaskCompletion() should update task state', () {
      // Setup
      final fakeFirestore = FakeFirebaseFirestore();
      final provider = IntegrationDayDetailProvider(
        dayNumber: 3,
        isDayCompletedInitially: false,
        firestoreInstance: fakeFirestore,
        userId: 'test-user-123',
      );

      // Initialize tasks
      provider.taskCompletion = {
        'Task 1': false,
        'Task 2': true,
      };

      // Toggle task 1 to true
      provider.toggleTaskCompletion('Task 1', true);
      expect(provider.taskCompletion['Task 1'], isTrue);
      expect(provider.taskCompletion['Task 2'], isTrue);

      // Toggle task 2 to false
      provider.toggleTaskCompletion('Task 2', false);
      expect(provider.taskCompletion['Task 1'], isTrue);
      expect(provider.taskCompletion['Task 2'], isFalse);

      // Toggle non-existent task (should add it)
      provider.toggleTaskCompletion('Task 3', true);
      expect(provider.taskCompletion['Task 3'], isTrue);
    });
  });
}