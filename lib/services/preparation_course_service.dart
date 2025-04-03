import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daymodule.dart';

class PreparationCourseService {
  final FirebaseFirestore firestore;

  PreparationCourseService(this.firestore);

  // Helper to reduce repetition when referencing the preparation data document.
  DocumentReference<Map<String, dynamic>> _prepDataRef(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('preparationData')
        .doc('data');
  }

  /// Fetch /users/{userId}/preparationData/data doc
  Future<Map<String, dynamic>?> getUserPreparationData(String userId) async {
    try {
      final doc = await _prepDataRef(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print("Error fetching preparation data for user $userId: $e");
      return null;
    }
  }

  /// Set or update startDate in Firestore
  Future<void> setUserStartDate(String userId, DateTime startDate) async {
    try {
      await _prepDataRef(userId).set({
        'startDate': startDate,
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error setting start date for user $userId: $e");
    }
  }

  /// Reset everything if date is in future, including PPS forms.
  /// This operation atomically resets startDate, modules, and deletes PPS forms using a batch write.
  Future<void> resetStartDateAndModules(String userId, List<DayModule> modules) async {
    try {
      final modulesData = modules.map((m) => m.toMap()).toList();
      final batch = firestore.batch();

      final prepDataRef = _prepDataRef(userId);
      final userDoc = firestore.collection('users').doc(userId);
      final beforeDoc = userDoc.collection('ppsForms').doc('before');
      final afterDoc = userDoc.collection('ppsForms').doc('after');

      // Overwrite preparation data to reset completions.
      batch.set(prepDataRef, {
        'startDate': null,
        'modules': modulesData,
      }, SetOptions(merge: false));

      // Schedule deletion of PPS forms.
      batch.delete(beforeDoc);
      batch.delete(afterDoc);

      // Commit the batch write atomically.
      await batch.commit();
    } catch (e) {
      print("Error resetting start date and modules for user $userId: $e");
    }
  }

  /// Overwrites modules array in Firestore
  Future<void> updateModuleState(String userId, List<DayModule> modules) async {
    try {
      final modulesData = modules.map((m) => m.toMap()).toList();
      await _prepDataRef(userId).set({
        'modules': modulesData,
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error updating module state for user $userId: $e");
    }
  }

  /// Updates a single module's completion state & tasks using a transaction for atomicity.
  Future<void> updateModuleCompletion(
      String userId,
      int dayNumber,
      bool isCompleted,
      Map<String, bool> taskCompletion,
      ) async {
    try {
      await firestore.runTransaction((transaction) async {
        final docRef = _prepDataRef(userId);
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final data = snapshot.data()!;
        List<dynamic> modulesData = data['modules'] ?? [];

        // Locate the relevant module and update its fields.
        for (int i = 0; i < modulesData.length; i++) {
          if (modulesData[i]['dayNumber'] == dayNumber) {
            modulesData[i]['isCompleted'] = isCompleted;
            modulesData[i]['tasks'] = Map<String, dynamic>.from(taskCompletion);
            break;
          }
        }

        transaction.update(docRef, {'modules': modulesData});
      });
    } catch (e) {
      print("Error updating module completion for user $userId, day $dayNumber: $e");
    }
  }

  /// Check if user has done PPS form
  Future<bool> hasPPSForm(String userId, bool isBeforeCourse) async {
    final docId = isBeforeCourse ? 'before' : 'after';
    try {
      final doc = await firestore
          .collection('users')
          .doc(userId)
          .collection('ppsForms')
          .doc(docId)
          .get();

      return doc.exists && doc.data() != null && doc.data()!['answers'] != null;
    } catch (e) {
      print("Error checking PPS form ($docId) for user $userId: $e");
      return false;
    }
  }
}
