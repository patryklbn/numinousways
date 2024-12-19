import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daymodule.dart';

class PreparationCourseService {
  final FirebaseFirestore firestore;

  PreparationCourseService(this.firestore);

  Future<Map<String, dynamic>?> getUserPreparationData(String userId) async {
    final doc = await firestore.collection('users').doc(userId).collection('preparationData').doc('data').get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  Future<void> setUserStartDate(String userId, DateTime startDate) async {
    await firestore.collection('users').doc(userId)
        .collection('preparationData')
        .doc('data')
        .set({'startDate': startDate}, SetOptions(merge: true));
  }

  Future<void> updateModuleState(String userId, List<DayModule> modules) async {
    // Convert modules to a JSON friendly format
    final modulesData = modules.map((m) {
      return {
        'dayNumber': m.dayNumber,
        'title': m.title,
        'description': m.description,
        'isLocked': m.isLocked,
        'isCompleted': m.isCompleted,
        // Tasks completion can be stored separately. For now, store if needed.
      };
    }).toList();

    await firestore.collection('users').doc(userId)
        .collection('preparationData')
        .doc('data')
        .set({'modules': modulesData}, SetOptions(merge: true));
  }

  Future<void> updateModuleCompletion(String userId, int dayNumber, bool isCompleted, Map<String, bool> taskCompletion) async {
    // Retrieve current modules
    final doc = await firestore.collection('users').doc(userId)
        .collection('preparationData').doc('data').get();
    if (!doc.exists) return;

    final data = doc.data()!;
    List<dynamic> modulesData = data['modules'] ?? [];
    for (int i = 0; i < modulesData.length; i++) {
      if (modulesData[i]['dayNumber'] == dayNumber) {
        modulesData[i]['isCompleted'] = isCompleted;
        // Convert taskCompletion map to a JSON-friendly structure
        final taskMap = <String, dynamic>{};
        taskCompletion.forEach((k, v) {
          taskMap[k] = v;
        });
        modulesData[i]['tasks'] = taskMap;
        break;
      }
    }

    await firestore.collection('users').doc(userId)
        .collection('preparationData')
        .doc('data')
        .set({'modules': modulesData}, SetOptions(merge: true));
  }
}
