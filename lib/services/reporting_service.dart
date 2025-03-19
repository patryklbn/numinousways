import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/content_report.dart';

class ReportingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _reportsCollection = 'reports';

  /// Submit a new content report
  Future<String> submitReport({
    required String contentId,
    required String contentType,
    required String reportedBy,
    required String reportedUserId,
    required ReportReason reason,
    required String additionalComments,
  }) async {
    try {
      final reportData = {
        'contentId': contentId,
        'contentType': contentType,
        'reportedBy': reportedBy,
        'reportedUserId': reportedUserId,
        'reason': reason.value,
        'additionalComments': additionalComments,
        'createdAt': FieldValue.serverTimestamp(),
        'status': ReportStatus.pending.toString().split('.').last,
        'moderatorNotes': null,
      };

      // Create a new report document
      final docRef = await _firestore.collection(_reportsCollection).add(reportData);
      return docRef.id;
    } catch (e) {
      print('Error submitting report: $e');
      throw Exception('Failed to submit report: $e');
    }
  }

  /// Get all reports submitted by a specific user
  Future<List<ContentReport>> getReportsByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_reportsCollection)
          .where('reportedBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ContentReport.fromDocument(doc))
          .toList();
    } catch (e) {
      print('Error fetching user reports: $e');
      throw Exception('Failed to fetch user reports: $e');
    }
  }

  /// Get all reports for a specific content item
  Future<List<ContentReport>> getReportsForContent(
      String contentId, String contentType) async {
    try {
      final querySnapshot = await _firestore
          .collection(_reportsCollection)
          .where('contentId', isEqualTo: contentId)
          .where('contentType', isEqualTo: contentType)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ContentReport.fromDocument(doc))
          .toList();
    } catch (e) {
      print('Error fetching content reports: $e');
      throw Exception('Failed to fetch content reports: $e');
    }
  }

  /// Update report status (for admin/moderator use)
  Future<void> updateReportStatus(
      String reportId, ReportStatus newStatus, {String? moderatorNotes}) async {
    try {
      final Map<String, dynamic> updateData = {
        'status': newStatus.toString().split('.').last,
      };

      if (moderatorNotes != null) {
        updateData['moderatorNotes'] = moderatorNotes;
      }

      await _firestore
          .collection(_reportsCollection)
          .doc(reportId)
          .update(updateData);
    } catch (e) {
      print('Error updating report status: $e');
      throw Exception('Failed to update report status: $e');
    }
  }

  /// Check if a user has already reported content
  Future<bool> hasUserReportedContent(
      String userId, String contentId, String contentType) async {
    try {
      final querySnapshot = await _firestore
          .collection(_reportsCollection)
          .where('reportedBy', isEqualTo: userId)
          .where('contentId', isEqualTo: contentId)
          .where('contentType', isEqualTo: contentType)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if user reported content: $e');
      throw Exception('Failed to check if user reported content: $e');
    }
  }
}