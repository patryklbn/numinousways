import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:numinous_ways/services/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService firestoreService;

  setUp(() {
    // Initialize a fake Firestore instance for each test
    fakeFirestore = FakeFirebaseFirestore();
    firestoreService = FirestoreService(firestore: fakeFirestore);
  });

  group('Firestore Service Tests', () {
    test('getFacilitators should return a stream of data from Firestore', () async {
      // Arrange
      await fakeFirestore.collection('facilitators').add({
        'name': 'Facilitator 1',
        'role': 'Role 1',
        'order': 1,
      });

      await fakeFirestore.collection('facilitators').add({
        'name': 'Facilitator 2',
        'role': 'Role 2',
        'order': 2,
      });

      // Act
      final facilitatorsStream = firestoreService.getFacilitators();

      // Assert
      final facilitators = await facilitatorsStream.first;
      expect(facilitators.length, 2);
      expect(facilitators[0].name, 'Facilitator 1'); // First by order
      expect(facilitators[1].name, 'Facilitator 2');
    });

    test('getVenues should return a stream of data from Firestore', () async {
      // Arrange
      await fakeFirestore.collection('venues').add({
        'name': 'Venue 1',
        'description': 'Description 1',
      });

      await fakeFirestore.collection('venues').add({
        'name': 'Venue 2',
        'description': 'Description 2',
      });

      // Act
      final venuesStream = firestoreService.getVenues();

      // Assert
      final venues = await venuesStream.first;
      expect(venues.length, 2);
      expect(venues.any((venue) => venue.name == 'Venue 1'), true);
      expect(venues.any((venue) => venue.name == 'Venue 2'), true);
    });

    test('deleteFacilitator should remove a document from Firestore', () async {
      // Arrange
      final docRef = await fakeFirestore.collection('facilitators').add({
        'name': 'Test Facilitator',
        'role': 'Test Role',
      });

      // Act
      await firestoreService.deleteFacilitator(docRef.id);

      // Assert
      final docSnapshot = await fakeFirestore.collection('facilitators').doc(docRef.id).get();
      expect(docSnapshot.exists, false);
    });

    test('deleteVenue should remove a document from Firestore', () async {
      // Arrange
      final docRef = await fakeFirestore.collection('venues').add({
        'name': 'Test Venue',
        'description': 'Test Description',
      });

      // Act
      await firestoreService.deleteVenue(docRef.id);

      // Assert
      final docSnapshot = await fakeFirestore.collection('venues').doc(docRef.id).get();
      expect(docSnapshot.exists, false);
    });
  });

}