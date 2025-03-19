import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportReason {
  inappropriate,
  harassment,
  spam,
  hateSpeech,
  violence,
  falseInformation,
  other
}

extension ReportReasonExtension on ReportReason {
  String get displayName {
    switch (this) {
      case ReportReason.inappropriate:
        return 'Inappropriate content';
      case ReportReason.harassment:
        return 'Harassment or bullying';
      case ReportReason.spam:
        return 'Spam or misleading';
      case ReportReason.hateSpeech:
        return 'Hate speech';
      case ReportReason.violence:
        return 'Violence or threatening content';
      case ReportReason.falseInformation:
        return 'False information';
      case ReportReason.other:
        return 'Other';
    }
  }

  String get value {
    return toString().split('.').last;
  }

  static ReportReason fromString(String value) {
    return ReportReason.values.firstWhere(
          (e) => e.toString().split('.').last == value,
      orElse: () => ReportReason.other,
    );
  }
}

enum ReportStatus {
  pending,
  underReview,
  resolved,
  dismissed
}

class ContentReport {
  final String id;
  final String contentId;
  final String contentType; // 'post' or 'comment'
  final String reportedBy;
  final String reportedUserId;
  final ReportReason reason;
  final String additionalComments;
  final Timestamp createdAt;
  final ReportStatus status;
  final String? moderatorNotes;

  ContentReport({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.reportedBy,
    required this.reportedUserId,
    required this.reason,
    required this.additionalComments,
    required this.createdAt,
    required this.status,
    this.moderatorNotes,
  });

  factory ContentReport.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ContentReport(
      id: doc.id,
      contentId: data['contentId'] ?? '',
      contentType: data['contentType'] ?? '',
      reportedBy: data['reportedBy'] ?? '',
      reportedUserId: data['reportedUserId'] ?? '',
      reason: ReportReasonExtension.fromString(data['reason'] ?? ''),
      additionalComments: data['additionalComments'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      status: ReportStatus.values.firstWhere(
            (e) => e.toString().split('.').last == (data['status'] ?? ''),
        orElse: () => ReportStatus.pending,
      ),
      moderatorNotes: data['moderatorNotes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contentId': contentId,
      'contentType': contentType,
      'reportedBy': reportedBy,
      'reportedUserId': reportedUserId,
      'reason': reason.value,
      'additionalComments': additionalComments,
      'createdAt': createdAt,
      'status': status.toString().split('.').last,
      'moderatorNotes': moderatorNotes,
    };
  }
}