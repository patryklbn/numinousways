import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      // Arrange - Add some test data directly to fake Firestore
      await fakeFirestore.collection('facilitators').add({
        'name': 'Facilitator 1',
        'role': 'Role 1',
        'order': 1,
        // Add other required fields for your Facilitator document
      });

      await fakeFirestore.collection('facilitators').add({
        'name': 'Facilitator 2',
        'role': 'Role 2',
        'order': 2,
        // Add other required fields for your Facilitator document
      });

      // Act - Get the stream of facilitators
      final facilitatorsStream = firestoreService.getFacilitators();

      // Assert - Verify we get the data in the correct order
      final facilitators = await facilitatorsStream.first;
      expect(facilitators.length, 2);
      expect(facilitators[0].name, 'Facilitator 1'); // First by order
      expect(facilitators[1].name, 'Facilitator 2');
    });

    test('getVenues should return a stream of data from Firestore', () async {
      // Arrange - Add some test data directly to fake Firestore
      await fakeFirestore.collection('venues').add({
        'name': 'Venue 1',
        'description': 'Description 1',
        // Add other required fields for your Venue document
      });

      await fakeFirestore.collection('venues').add({
        'name': 'Venue 2',
        'description': 'Description 2',
        // Add other required fields for your Venue document
      });

      // Act - Get the stream of venues
      final venuesStream = firestoreService.getVenues();

      // Assert - Verify we get both venues
      final venues = await venuesStream.first;
      expect(venues.length, 2);
      // Since venues aren't ordered, just check that both venues exist
      expect(venues.any((venue) => venue.name == 'Venue 1'), true);
      expect(venues.any((venue) => venue.name == 'Venue 2'), true);
    });

    test('deleteFacilitator should remove a document from Firestore', () async {
      // Arrange - Add a test document
      final docRef = await fakeFirestore.collection('facilitators').add({
        'name': 'Test Facilitator',
        'role': 'Test Role',
        // Add other required fields for your Facilitator document
      });

      // Act - Delete the facilitator
      await firestoreService.deleteFacilitator(docRef.id);

      // Assert - Verify the document is deleted
      final docSnapshot = await fakeFirestore.collection('facilitators').doc(docRef.id).get();
      expect(docSnapshot.exists, false);
    });

    test('deleteVenue should remove a document from Firestore', () async {
      // Arrange - Add a test document
      final docRef = await fakeFirestore.collection('venues').add({
        'name': 'Test Venue',
        'description': 'Test Description',
        // Add other required fields for your Venue document
      });

      // Act - Delete the venue
      await firestoreService.deleteVenue(docRef.id);

      // Assert - Verify the document is deleted
      final docSnapshot = await fakeFirestore.collection('venues').doc(docRef.id).get();
      expect(docSnapshot.exists, false);
    });
  });

}