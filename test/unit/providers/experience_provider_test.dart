import 'package:flutter_test/flutter_test.dart';
import 'package:numinous_ways/services/retreat_service.dart';
import 'package:numinous_ways/models/experience/participant.dart';
import 'package:numinous_ways/viewmodels/experience_provider.dart';


class MockRetreatService implements RetreatService {
  bool returnEnrollmentValue = false;
  Participant? returnParticipantValue;
  Exception? throwException;

  int isUserEnrolledCallCount = 0;
  int getParticipantCallCount = 0;
  int addOrUpdateParticipantCallCount = 0;

  String? lastRetreatId;
  String? lastUserId;
  Participant? lastParticipant;

  @override
  Future<bool> isUserEnrolled(String retreatId, String userId) async {
    if (throwException != null) throw throwException!;
    isUserEnrolledCallCount++;
    lastRetreatId = retreatId;
    lastUserId = userId;
    return returnEnrollmentValue;
  }

  @override
  Future<Participant?> getParticipant(String retreatId, String userId) async {
    if (throwException != null) throw throwException!;
    getParticipantCallCount++;
    lastRetreatId = retreatId;
    lastUserId = userId;
    return returnParticipantValue;
  }

  @override
  Future<void> addOrUpdateParticipant(String retreatId, Participant participant) async {
    if (throwException != null) throw throwException!;
    addOrUpdateParticipantCallCount++;
    lastRetreatId = retreatId;
    lastParticipant = participant;
  }


  @override
  Future<List<Participant>> getAllParticipants(String retreatId) async => [];

  @override
  Future<void> enrollUser(String retreatId, String userId) async {}


  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockRetreatService mockRetreatService;
  late ExperienceProvider provider;

  const String testUserId = 'test-user-123';
  const String testRetreatId = 'test-retreat-456';

  setUp(() {
    mockRetreatService = MockRetreatService();

    // Initialize provider with mock service and test user ID
    provider = ExperienceProvider(
      retreatService: mockRetreatService,
      userId: testUserId,
    );
  });

  group('ExperienceProvider Tests', () {
    test('Initial state should be correct', () {
      expect(provider.userId, equals(testUserId));
    });

    test('checkEnrollment() should return enrollment status from service', () async {

      mockRetreatService.returnEnrollmentValue = true;

      // Execute
      final result = await provider.checkEnrollment(testRetreatId);

      // Verify
      expect(result, isTrue);
      expect(mockRetreatService.isUserEnrolledCallCount, 1);
      expect(mockRetreatService.lastRetreatId, testRetreatId);
      expect(mockRetreatService.lastUserId, testUserId);
    });

    test('checkEnrollment() should return false when userId is null', () async {
      // Setup provider with null userId
      provider = ExperienceProvider(
        retreatService: mockRetreatService,
        userId: null,
      );

      // Execute
      final result = await provider.checkEnrollment(testRetreatId);

      // Verify
      expect(result, isFalse);
      expect(mockRetreatService.isUserEnrolledCallCount, 0); // No service call
    });

    test('fetchParticipant() should return participant data from service', () async {
      // Create a test participant
      final testParticipant = Participant(
        userId: testUserId,
        role: 'enrolled',
        shareBio: true,
        meqConsent: false,
        name: 'Test User',
        aboutYourself: 'About me',
      );

      // Setup mock behavior
      mockRetreatService.returnParticipantValue = testParticipant;

      // Execute
      final result = await provider.fetchParticipant(testRetreatId);

      // Verify
      expect(result, equals(testParticipant));
      expect(mockRetreatService.getParticipantCallCount, 1);
      expect(mockRetreatService.lastRetreatId, testRetreatId);
      expect(mockRetreatService.lastUserId, testUserId);
    });

    test('fetchParticipant() should return null when userId is null', () async {
      // Setup provider with null userId
      provider = ExperienceProvider(
        retreatService: mockRetreatService,
        userId: null,
      );

      // Execute
      final result = await provider.fetchParticipant(testRetreatId);

      // Verify
      expect(result, isNull);
      expect(mockRetreatService.getParticipantCallCount, 0); // No service call
    });

    test('updateMEQConsent() should update participant MEQ consent and return updated participant', () async {
      // Create a test participant with meqConsent = false
      final testParticipant = Participant(
        userId: testUserId,
        role: 'enrolled',
        shareBio: true,
        meqConsent: false,
        name: 'Test User',
      );

      // Execute
      final result = await provider.updateMEQConsent(testRetreatId, testParticipant);

      // Verify
      expect(result.meqConsent, isTrue); // Check that consent is now true
      expect(result.userId, equals(testParticipant.userId)); // Check that other fields remain unchanged
      expect(result.name, equals(testParticipant.name));

      // Verify the service was called with correct parameters
      expect(mockRetreatService.addOrUpdateParticipantCallCount, 1);
      expect(mockRetreatService.lastRetreatId, testRetreatId);
      expect(mockRetreatService.lastParticipant?.meqConsent, isTrue);
      expect(mockRetreatService.lastParticipant?.userId, testUserId);
    });
  });

  group('Edge cases', () {
    test('Service exceptions should be propagated', () async {
      // Setup mock to throw an exception
      mockRetreatService.throwException = Exception('Network error');

      // Execute and expect exception
      expect(
            () => provider.checkEnrollment(testRetreatId),
        throwsException,
      );
    });

    test('Null values in participant should be handled correctly during updates', () async {
      // Create a test participant with some null values
      final testParticipant = Participant(
        userId: testUserId,
        role: 'enrolled',
        shareBio: true,
        meqConsent: false,
        detailedBio: null,
        photoUrl: null,
      );

      // Execute
      final result = await provider.updateMEQConsent(testRetreatId, testParticipant);

      // Verify null values remain null after update
      expect(result.detailedBio, isNull);
      expect(result.photoUrl, isNull);
      expect(result.meqConsent, isTrue);
    });
  });
}