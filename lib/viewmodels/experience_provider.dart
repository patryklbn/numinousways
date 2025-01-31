import 'package:flutter/material.dart';
import '../services/retreat_service.dart';
import '../models/experience/retreat.dart';
import '../models/experience/participant.dart';

/// ExperienceProvider handles retreat-specific logic, such as:
///  - Checking if the current user is enrolled
///  - Possibly loading additional retreat data or participants
class ExperienceProvider extends ChangeNotifier {
  final RetreatService _retreatService;
  final String? userId;  // The current logged-in user's ID

  ExperienceProvider({
    required RetreatService retreatService,
    required this.userId,
  }) : _retreatService = retreatService;

  /// Check if the user is enrolled in a specific retreat
  Future<bool> checkEnrollment(String retreatId) async {
    // If user is not logged in, definitely not enrolled
    if (userId == null) return false;

    final isEnrolled = await _retreatService.isUserEnrolled(retreatId, userId!);
    return isEnrolled;
  }
}
