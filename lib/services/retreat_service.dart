import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/experience/retreat.dart';
import '../models/experience/participant.dart';
import '../models/facilitator.dart';
import '../models/venue.dart';

class RetreatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // =======================
  // Retreat methods
  // =======================

  Future<List<Retreat>> fetchActiveRetreats() async {
    final query = await _db
        .collection('retreats')
        .where('isArchived', isEqualTo: false)
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

  /// ✅ **Check if a user is enrolled in a specific retreat**
  Future<bool> isUserEnrolled(String retreatId, String userId) async {
    try {
      final docSnap = await _db
          .collection('retreats')
          .doc(retreatId)
          .collection('participants')
          .doc(userId)
          .get();

      if (!docSnap.exists) {
        print("❌ User $userId NOT found in participants for retreat $retreatId.");
        return false;
      }

      final data = docSnap.data();
      final role = data?['role'] as String?;
      print("✅ User $userId role: $role");

      return role == 'enrolled';
    } catch (e) {
      print("🔥 Error checking enrollment: $e");
      return false;
    }
  }

  /// ✅ **Enroll a user in a retreat**
  Future<void> enrollUser(String retreatId, String userId) async {
    final participantRef = _db
        .collection('retreats')
        .doc(retreatId)
        .collection('participants')
        .doc(userId);

    await participantRef.set({
      'role': 'enrolled',
      'shareBio': false, // Default values
      'detailedBio': null,
      'meqConsent': false,
    }, SetOptions(merge: true));

    print("✅ User $userId successfully enrolled in retreat $retreatId.");
  }

  /// ✅ **Add or update a participant in a retreat**
  Future<void> addOrUpdateParticipant(String retreatId, Participant participant) async {
    await _db
        .collection('retreats')
        .doc(retreatId)
        .collection('participants')
        .doc(participant.userId)
        .set(participant.toMap(), SetOptions(merge: true));
  }

  /// ✅ **Fetch a specific participant**
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

  /// ✅ **Fetch all participants of a retreat**
  Future<List<Participant>> getAllParticipants(String retreatId) async {
    final querySnap = await _db
        .collection('retreats')
        .doc(retreatId)
        .collection('participants')
        .get();

    return querySnap.docs.map((doc) => Participant.fromDocument(doc)).toList();
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
}
