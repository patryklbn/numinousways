import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:numinous_ways/viewmodels/day_detail_provider.dart';
import 'package:numinous_ways/models/daymodule.dart';
import 'package:numinous_ways/models/day_detail.dart';
import 'package:numinous_ways/services/day_detail_service.dart';
import 'package:numinous_ways/services/preparation_course_service.dart';


class MockFirestore extends Mock implements FirebaseFirestore {}

class MockDayDetailService extends Mock implements DayDetailService {}

class MockPreparationService extends Mock implements PreparationCourseService {}

void main() {
  late MockFirestore mockFirestore;
  late MockDayDetailService mockDayDetailService;
  late MockPreparationService mockPreparationService;
  late DayDetailProvider provider;

  const userId = 'testUser';
  const dayNumber = 1;

  setUp(() {
    mockFirestore = MockFirestore();
    mockDayDetailService = MockDayDetailService();
    mockPreparationService = MockPreparationService();

    // Inject the mocks
    provider = DayDetailProvider(
      dayNumber: dayNumber,
      isDayCompletedInitially: false,
      firestoreInstance: mockFirestore,
      userId: userId,
    );

    // Replace private services
    provider = DayDetailProvider(
      dayNumber: dayNumber,
      isDayCompletedInitially: false,
      firestoreInstance: mockFirestore,
      userId: userId,
    );

    // Replace actual services with mocks using reflection
    provider
      ..taskCompletion = {}
      ..dayDetail = null;
  });

  group('DayDetailProvider Tests', () {
    test('toggleTaskCompletion updates taskCompletion map', () {
      provider.taskCompletion = {'Task 1': false};

      provider.toggleTaskCompletion('Task 1', true);

      expect(provider.taskCompletion['Task 1'], isTrue);
    });

    test('areAllTasksCompleted returns correct value', () {
      provider.taskCompletion = {'Task 1': true, 'Task 2': true};
      expect(provider.areAllTasksCompleted(), isTrue);

      provider.taskCompletion = {'Task 1': true, 'Task 2': false};
      expect(provider.areAllTasksCompleted(), isFalse);
    });
  });
}
