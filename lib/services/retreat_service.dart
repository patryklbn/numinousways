import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/experience/retreat.dart';
import '../models/experience/participant.dart';
import '../models/facilitator.dart';
import '../models/venue.dart';
import '../../../models/experience/travel_details.dart';
import '../models/experience/psychedelic_order.dart';
import '../models/experience/meq_submission.dart';

class RetreatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // =======================
  // Retreat methods
  // =======================

  Future<List<Retreat>> fetchActiveRetreats() async {
    final query = await _db
        .collection('retreats')
        .where('isArchived', isEqualTo: false)
        .orderBy('startDate', descending: false)
        .get();
    return query.docs.map((doc) => Retreat.fromDocument(doc)).toList();
  }

  Future<Retreat?> getRetreatById(String retreatId) async {
    final docSnap = await _db.collection('retreats').doc(retreatId).get();
    if (!docSnap.exists) return null;
    return Retreat.fromDocument(docSnap);
  }

  Future<String> addRetreat(Retreat retreat) async {
    final docRef = await _db.collection('retreats').add(retreat.toMap());
    return docRef.id;
  }

  Future<void> updateRetreat(Retreat retreat) async {
    await _db.collection('retreats').doc(retreat.id).update(retreat.toMap());
  }

  // =======================
  // Participant methods
  // =======================

  /// Check if a user is enrolled in a specific retreat
  Future<bool> isUserEnrolled(String retreatId, String userId) async {
    try {
      final docRef = _db
          .collection('retreats')
          .doc(retreatId)
          .collection('participants')
          .doc(userId);

      final docSnap = await docRef.get(const GetOptions(source: Source.server));

      if (!docSnap.exists) return false;

      final data = docSnap.data();
      final role = data?['role'] as String?;

      if (role == null) return false;
      return role == 'enrolled';
    } catch (e) {
      return false;
    }
  }

  /// Enroll a user in a retreat
  Future<void> enrollUser(String retreatId, String userId) async {
    final participantRef = _db
        .collection('retreats')
        .doc(retreatId)
        .collection('participants')
        .doc(userId);

    await participantRef.set({
      'role': 'enrolled',
      'shareBio': false,
      'detailedBio': null,
      'meqConsent': false,
    }, SetOptions(merge: true));
  }

  /// Add or update a participant in a retreat
  Future<void> addOrUpdateParticipant(String retreatId, Participant participant) async {
    await _db
        .collection('retreats')
        .doc(retreatId)
        .collection('participants')
        .doc(participant.userId)
        .set(participant.toMap(), SetOptions(merge: true));
  }

  /// Fetch a specific participant
  Future<Participant?> getParticipant(String retreatId, String userId) async {
    final docSnap = await _db
        .collection('retreats')
        .doc(retreatId)
        .collection('participants')
        .doc(userId)
        .get();

    if (!docSnap.exists) return null;
    return Participant.fromDocument(docSnap);
  }

  /// Fetch all participants of a retreat
  Future<List<Participant>> getAllParticipants(String retreatId) async {
    final querySnap = await _db
        .collection('retreats')
        .doc(retreatId)
        .collection('participants')
        .get();

    return querySnap.docs.map((doc) => Participant.fromDocument(doc)).toList();
  }

  // =======================
  // Photo Upload for Participant
  // =======================
  Future<String> uploadParticipantPhoto(String retreatId, String userId, File photoFile) async {
    try {
      final storageRef = _storage.ref().child('retreats/$retreatId/participants/$userId/photo.jpg');
      UploadTask uploadTask = storageRef.putFile(photoFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  // =======================
  // Psychedelic Order
  // =======================
  Future<void> submitPsychedelicOrder(String retreatId, PsychedelicOrder order) async {
    final docRef = _db
        .collection('retreats')
        .doc(retreatId)
        .collection('psychedelicOrders')
        .doc(order.userId);

    await docRef.set(order.toMap(), SetOptions(merge: true));
  }

  // =======================
  // Travel Details
  // =======================
  Future<void> submitTravelDetails(String retreatId, TravelDetails details) async {
    final docRef = _db
        .collection('retreats')
        .doc(retreatId)
        .collection('travelDetails')
        .doc(details.userId);

    await docRef.set(details.toMap(), SetOptions(merge: true));
  }

  // =======================
  // Facilitators for a Retreat
  // =======================
  Future<List<Facilitator>> getFacilitatorsForRetreat(String retreatId) async {
    final retreatDoc = await _db.collection('retreats').doc(retreatId).get();
    if (!retreatDoc.exists) return [];

    final retreat = Retreat.fromDocument(retreatDoc);
    if (retreat.facilitatorIds.isEmpty) {
      return [];
    }

    final query = await _db
        .collection('facilitators')
        .where(FieldPath.documentId, whereIn: retreat.facilitatorIds)
        .get();

    return query.docs.map((doc) => Facilitator.fromDocument(doc)).toList();
  }

  // =======================
  // Venue for a Retreat
  // =======================
  Future<Venue?> getVenueById(String venueId) async {
    final docSnap = await _db.collection('venues').doc(venueId).get();
    if (!docSnap.exists) return null;
    return Venue.fromDocument(docSnap);
  }

  // =======================
  // MEQ-30 Submissions
  // =======================
  Future<MEQSubmission?> getMEQSubmission(String retreatId, String userId) async {
    try {
      final doc = await _db
          .collection('retreats')
          .doc(retreatId)
          .collection('meqSubmissions')
          .doc(userId)
          .get();

      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;

      return MEQSubmission.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  Future<void> submitMEQSubmission(String retreatId, MEQSubmission submission) async {
    final docRef = _db
        .collection('retreats')
        .doc(retreatId)
        .collection('meqSubmissions')
        .doc(submission.userId);

    await docRef.set(submission.toMap(), SetOptions(merge: true));
  }

  // =======================
  // Feedback
  // =======================
  Future<void> submitFeedback(String retreatId, String userId, Map<String, dynamic> feedbackData) async {
    final docRef = _db
        .collection('retreats')
        .doc(retreatId)
        .collection('feedback')
        .doc(userId);

    await docRef.set(feedbackData, SetOptions(merge: true));
  }
}
