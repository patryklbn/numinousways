import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daymodule.dart';

class PreparationCourseService {
  final FirebaseFirestore firestore;

  PreparationCourseService(this.firestore);

  /// Fetch /users/{userId}/preparationData/data doc
  Future<Map<String, dynamic>?> getUserPreparationData(String userId) async {
    final doc = await firestore
        .collection('users')
        .doc(userId)
        .collection('preparationData')
        .doc('data')
        .get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  /// Set or update startDate in Firestore
  Future<void> setUserStartDate(String userId, DateTime startDate) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('preparationData')
        .doc('data')
        .set({
      'startDate': startDate,
    }, SetOptions(merge: true));
  }

  /// Reset everything if date is in future, including PPS forms
  Future<void> resetStartDateAndModules(String userId, List<DayModule> modules) async {
    final modulesData = modules.map((m) => {
      'dayNumber': m.dayNumber,
      'title': m.title,
      'description': m.description,
      'isLocked': m.isLocked,
      'isCompleted': m.isCompleted,
    }).toList();

    final userDoc = firestore.collection('users').doc(userId);

    // Overwrite preparation data (do not merge) to reset completions.
    await firestore
        .collection('users')
        .doc(userId)
        .collection('preparationData')
        .doc('data')
        .set({
      'startDate': null,  // Clear startDate
      'modules': modulesData,
    }, SetOptions(merge: false));

    // Reset PPS forms by deleting the existing form documents
    final ppsForms = userDoc.collection('ppsForms');
    try {
      await ppsForms.doc('before').delete();
    } catch (_) {}
    try {
      await ppsForms.doc('after').delete();
    } catch (_) {}
  }

  /// Overwrites modules array in Firestore
  Future<void> updateModuleState(String userId, List<DayModule> modules) async {
    final modulesData = modules.map((m) => {
      'dayNumber': m.dayNumber,
      'title': m.title,
      'description': m.description,
      'isLocked': m.isLocked,
      'isCompleted': m.isCompleted,
    }).toList();

    await firestore
        .collection('users')
        .doc(userId)
        .collection('preparationData')
        .doc('data')
        .set({
      'modules': modulesData,
    }, SetOptions(merge: true));
  }

  /// Updates a single module's completion state & tasks
  Future<void> updateModuleCompletion(
      String userId,
      int dayNumber,
      bool isCompleted,
      Map<String, bool> taskCompletion,
      ) async {
    final doc = await firestore
        .collection('users')
        .doc(userId)
        .collection('preparationData')
        .doc('data')
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;
    List<dynamic> modulesData = data['modules'] ?? [];
    for (int i = 0; i < modulesData.length; i++) {
      if (modulesData[i]['dayNumber'] == dayNumber) {
        modulesData[i]['isCompleted'] = isCompleted;
        final taskMap = <String, dynamic>{};
        taskCompletion.forEach((k, v) => taskMap[k] = v);
        modulesData[i]['tasks'] = taskMap;
        break;
      }
    }

    await firestore
        .collection('users')
        .doc(userId)
        .collection('preparationData')
        .doc('data')
        .set({'modules': modulesData}, SetOptions(merge: true));
  }

  /// Check if user has done PPS form
  Future<bool> hasPPSForm(String userId, bool isBeforeCourse) async {
    final docId = isBeforeCourse ? 'before' : 'after';
    final doc = await firestore
        .collection('users')
        .doc(userId)
        .collection('ppsForms')
        .doc(docId)
        .get();

    return doc.exists && doc.data() != null && doc.data()!['answers'] != null;
  }
}
