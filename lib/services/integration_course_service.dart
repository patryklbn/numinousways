import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daymodule.dart';

class IntegrationCourseService {
  final FirebaseFirestore firestore;

  IntegrationCourseService(this.firestore);

  // Collection
  DocumentReference<Map<String, dynamic>> _integrationDataRef(String userId) =>
      firestore.collection('users').doc(userId).collection('integrationData').doc('data');

  CollectionReference<Map<String, dynamic>> _journalRef(String userId) =>
      firestore.collection('users').doc(userId).collection('integrationJournal');

  CollectionReference<Map<String, dynamic>> _moodRef(String userId) =>
      firestore.collection('users').doc(userId).collection('integrationMood');

  DocumentReference<Map<String, dynamic>> _integrationContentRef() =>
      firestore.collection('integrationContent').doc('days');

  /// Fetch users integration data and merge with admin content
  Future<Map<String, dynamic>?> getUserIntegrationData(String userId) async {
    try {
      final userDoc = await _integrationDataRef(userId).get();
      if (!userDoc.exists) return null;

      // Get admin-managed content
      final contentDoc = await _integrationContentRef().get();
      final adminContent = contentDoc.data() ?? {};

      final List<Map<String, dynamic>> modules = [];
      if (userDoc.data()?['modules'] != null) {
        // Merge user progress with admin content
        for (var userModule in userDoc.data()!['modules']) {
          final dayNumber = userModule['dayNumber'];
          final adminDayContent = adminContent[dayNumber.toString()];

          if (adminDayContent != null) {
            modules.add({
              ...userModule,
              'title': adminDayContent['title'] ?? 'Day $dayNumber',
              'description': adminDayContent['description'] ?? 'Integration practice for day $dayNumber',
              'content': adminDayContent['content'] ?? {},
            });
          } else {
            modules.add(userModule);
          }
        }
      }

      return {
        'startDate': userDoc.data()?['startDate'],
        'modules': modules,
      };
    } catch (e) {
      print("Error fetching integration data: $e");
      return null;
    }
  }

  /// Set the course start date
  Future<void> setUserStartDate(String userId, DateTime startDate) async {
    try {
      await _integrationDataRef(userId).set({
        'startDate': startDate,
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error setting start date: $e");
      throw Exception("Failed to set start date");
    }
  }



  /// Reset the entire integration course
  Future<void> resetCourse(String userId, List<DayModule> modules) async {
    try {
      final batch = firestore.batch();
      final freshData = {
        'startDate': null,
        'modules': modules.map((m) => m.toMap()).toList(),
      };

      // Reset main data
      batch.set(_integrationDataRef(userId), freshData, SetOptions(merge: false));

      // Delete all journal entries
      final journalDocs = await _journalRef(userId).get();
      for (var doc in journalDocs.docs) {
        batch.delete(doc.reference);
      }

      // Delete all mood entries
      final moodDocs = await _moodRef(userId).get();
      for (var doc in moodDocs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print("Error resetting course: $e");
      throw Exception("Failed to reset integration course");
    }
  }

  /// Update module states
  Future<void> updateModuleState(String userId, List<DayModule> modules) async {
    try {
      await _integrationDataRef(userId).set({
        'modules': modules.map((m) => m.toMap()).toList(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error updating modules: $e");
      throw Exception("Failed to update modules");
    }
  }

  /// Update single module completion status
  Future<void> updateModuleCompletion(
      String userId,
      int dayNumber,
      bool isCompleted,
      Map<String, bool> taskCompletion,
      ) async {
    try {
      await firestore.runTransaction((transaction) async {
        final docRef = _integrationDataRef(userId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception("Integration data not found");
        }

        final data = snapshot.data()!;
        final List<dynamic> modules = List.from(data['modules'] ?? []);

        final moduleIndex = modules.indexWhere((m) => m['dayNumber'] == dayNumber);
        if (moduleIndex == -1) {
          throw Exception("Module not found");
        }

        modules[moduleIndex] = {
          ...modules[moduleIndex],
          'isCompleted': isCompleted,
          'tasks': taskCompletion,
        };

        transaction.update(docRef, {'modules': modules});
      });
    } catch (e) {
      print("Error updating module completion: $e");
      throw Exception("Failed to update module completion");
    }
  }

  /// Save a journal entry
  Future<void> saveJournalEntry(String userId, int dayNumber, String content) async {
    try {
      await _journalRef(userId).doc('day_$dayNumber').set({
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error saving journal entry: $e");
      throw Exception("Failed to save journal entry");
    }
  }

  /// Get a journal entry
  Future<String?> getJournalEntry(String userId, int dayNumber) async {
    try {
      final doc = await _journalRef(userId).doc('day_$dayNumber').get();
      final data = doc.data();
      if (doc.exists && data != null) {
        return data['content'] as String?;
      }
      return null;
    } catch (e) {
      print("Error fetching journal entry: $e");
      throw Exception("Failed to fetch journal entry");
    }
  }

  /// Save mood rating
  Future<void> saveMoodRating(
      String userId,
      int dayNumber, {
        required int rating,
        required List<String> emotions,
        String? note,
      }) async {
    try {
      await _moodRef(userId).doc('day_$dayNumber').set({
        'rating': rating,
        'emotions': emotions,
        'note': note,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error saving mood rating: $e");
      throw Exception("Failed to save mood rating");
    }
  }

  /// Get mood rating for a specific day
  Future<Map<String, dynamic>?> getMoodRating(String userId, int dayNumber) async {
    try {
      final doc = await _moodRef(userId).doc('day_$dayNumber').get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print("Error fetching mood rating: $e");
      throw Exception("Failed to fetch mood rating");
    }
  }

  /// Get mood history
  Future<List<Map<String, dynamic>>> getMoodHistory(String userId) async {
    try {
      final querySnapshot = await _moodRef(userId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => {
        ...doc.data(),
        'dayNumber': int.parse(doc.id.split('_')[1]),
      }).toList();
    } catch (e) {
      print("Error fetching mood history: $e");
      throw Exception("Failed to fetch mood history");
    }
  }
}