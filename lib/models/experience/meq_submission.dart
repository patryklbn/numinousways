// In meq_submission.dart (example):
class MEQSubmission {
  final String userId;
  final String nameOrPseudonym;
  final DateTime dateSubmitted;
  final Map<String, double> meq1Answers;
  final Map<String, double> meq2Answers;
  final bool completedExp1;
  final bool completedExp2; // Instead of a single "completed"

  MEQSubmission({
    required this.userId,
    required this.nameOrPseudonym,
    required this.dateSubmitted,
    required this.meq1Answers,
    required this.meq2Answers,
    this.completedExp1 = false,
    this.completedExp2 = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nameOrPseudonym': nameOrPseudonym,
      'dateSubmitted': dateSubmitted.toIso8601String(),
      'meq1Answers': meq1Answers,
      'meq2Answers': meq2Answers,
      'completedExp1': completedExp1,
      'completedExp2': completedExp2,
    };
  }

  factory MEQSubmission.fromMap(Map<String, dynamic> map) {
    return MEQSubmission(
      userId: map['userId'] ?? '',
      nameOrPseudonym: map['nameOrPseudonym'] ?? '',
      dateSubmitted: map['dateSubmitted'] != null
          ? DateTime.parse(map['dateSubmitted'])
          : DateTime.now(),
      meq1Answers: Map<String, double>.from(map['meq1Answers'] ?? {}),
      meq2Answers: Map<String, double>.from(map['meq2Answers'] ?? {}),
      completedExp1: map['completedExp1'] ?? false,
      completedExp2: map['completedExp2'] ?? false,
    );
  }
}
