import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/facilitator.dart';
import '../models/venue.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  // Constructor with dependency injection
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // -------------------------
  // Facilitators
  // -------------------------

  Stream<List<Facilitator>> getFacilitators() {
    return _db
        .collection('facilitators')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Facilitator.fromDocument(doc)).toList());
  }

  Future<void> addFacilitator(Facilitator facilitator) {
    return _db.collection('facilitators').add(facilitator.toMap());
  }

  Future<void> updateFacilitator(Facilitator facilitator) {
    return _db
        .collection('facilitators')
        .doc(facilitator.id)
        .update(facilitator.toMap());
  }

  Future<void> deleteFacilitator(String id) {
    return _db.collection('facilitators').doc(id).delete();
  }

  // -------------------------
  // Venues
  // -------------------------

  Stream<List<Venue>> getVenues() {
    return _db.collection('venues').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Venue.fromDocument(doc)).toList());
  }

  Future<void> addVenue(Venue venue) {
    return _db.collection('venues').add(venue.toMap());
  }

  Future<void> updateVenue(Venue venue) {
    return _db.collection('venues').doc(venue.id).update(venue.toMap());
  }

  Future<void> deleteVenue(String id) {
    return _db.collection('venues').doc(id).delete();
  }
}