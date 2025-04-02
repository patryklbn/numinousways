import 'package:flutter/material.dart';
import '../services/retreat_service.dart';
import '../models/experience/participant.dart';


class ExperienceProvider extends ChangeNotifier {
  final RetreatService _retreatService;
  final String? userId;

  ExperienceProvider({
    required RetreatService retreatService,
    required this.userId,
  }) : _retreatService = retreatService;

  /// Check if the user is enrolled in a specific retreat.
  Future<bool> checkEnrollment(String retreatId) async {
    if (userId == null) return false;
    return await _retreatService.isUserEnrolled(retreatId, userId!);
  }

  /// Retrieve the participant record for the current user in the given retreat.
  Future<Participant?> fetchParticipant(String retreatId) async {
    if (userId == null) return null;
    return await _retreatService.getParticipant(retreatId, userId!);
  }
  /// Updates the participant record to indicate that MEQ consent has been given.
  Future<Participant> updateMEQConsent(String retreatId, Participant participant) async {
    final updated = participant.copyWith(meqConsent: true);
    await _retreatService.addOrUpdateParticipant(retreatId, updated);
    return updated;
  }
}
