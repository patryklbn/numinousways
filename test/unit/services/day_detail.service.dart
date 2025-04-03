import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:numinous_ways/services/day_detail_service.dart';
import 'package:numinous_ways/models/day_detail.dart';

void main() {
  group('DayDetailService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late DayDetailService dayDetailService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      dayDetailService = DayDetailService(firestore: fakeFirestore);
    });

    test('getDayDetail returns correct day details when day exists', () async {
      // Arrange
      final dayNumber = 1;
      await fakeFirestore.collection('days').doc('$dayNumber').set({
        'title': 'Test Day 1',
        'heroImagePath': 'assets/images/test_hero.jpg',
        'tasks': [
          {
            'dayNumber': 1,
            'title': 'Task 1',
            'description': 'Task 1 description',
            'isLocked': false,
            'isCompleted': false
          },
          {
            'dayNumber': 1,
            'title': 'Task 2',
            'description': 'Task 2 description',
            'isLocked': false,
            'isCompleted': false
          }
        ],
        'meditationTitle': 'Test Meditation',
        'meditationUrl': 'https://example.com/meditation.mp3',
        'articles': [
          {
            'title': 'Article 1',
            'url': 'https://example.com/article1',
            'description': 'Description for article 1'
          }
        ]
      });

      // Act
      final result = await dayDetailService.getDayDetail(dayNumber);

      // Assert
      expect(result, isA<DayDetail>());
      expect(result.dayNumber, dayNumber);
      expect(result.title, 'Test Day 1');
      expect(result.heroImagePath, 'assets/images/test_hero.jpg');
      expect(result.tasks, hasLength(2));

      // Test properties that exist on DayModule
      expect(result.tasks[0].dayNumber, 1);
      expect(result.tasks[0].title, 'Task 1');
      expect(result.tasks[0].description, 'Task 1 description');
      expect(result.tasks[0].isLocked, false);
      expect(result.tasks[0].isCompleted, false);

      expect(result.tasks[1].dayNumber, 1);
      expect(result.tasks[1].title, 'Task 2');
      expect(result.tasks[1].description, 'Task 2 description');

      expect(result.meditationTitle, 'Test Meditation');
      expect(result.meditationUrl, 'https://example.com/meditation.mp3');
      expect(result.articles, hasLength(1));

      // Test properties that exist on Article
      expect(result.articles[0].title, 'Article 1');
      expect(result.articles[0].url, 'https://example.com/article1');
      expect(result.articles[0].description, 'Description for article 1');
    });

    test('getDayDetail handles missing optional fields', () async {
      // Arrange
      final dayNumber = 2;
      await fakeFirestore.collection('days').doc('$dayNumber').set({
        'title': 'Minimal Day',
        'heroImagePath': 'assets/images/minimal.jpg',
        // Omit optional fields
      });

      // Act
      final result = await dayDetailService.getDayDetail(dayNumber);

      // Assert
      expect(result, isA<DayDetail>());
      expect(result.dayNumber, dayNumber);
      expect(result.title, 'Minimal Day');
      expect(result.heroImagePath, 'assets/images/minimal.jpg');
      expect(result.tasks, isEmpty);
      expect(result.meditationTitle, '');
      expect(result.meditationUrl, '');
      expect(result.articles, isEmpty);
    });

    test('getDayDetail throws exception when day does not exist', () async {
      // Act & Assert
      expect(
            () => dayDetailService.getDayDetail(999),
        throwsA(isA<Exception>().having(
                (e) => e.toString(),
            'message',
            contains('Day detail not found for day 999')
        )),
      );
    });
  });
}