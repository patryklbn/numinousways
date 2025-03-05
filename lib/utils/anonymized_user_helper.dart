import 'package:flutter/material.dart';

/// Helper utility class for displaying anonymized users consistently across the app
class AnonymizedUserHelper {
  static const String anonymousId = 'anonymous_user';
  static const String displayName = 'Deleted User';

  /// Check if a userId belongs to an anonymized user
  static bool isAnonymizedUser(String? userId) {
    if (userId == null) return false;
    return userId == anonymousId || userId.startsWith('anonymous_');
  }

  /// Get the display name for a user, handling anonymized users
  static String getDisplayName(String? userId, String? userName) {
    if (isAnonymizedUser(userId)) {
      return displayName;
    }
    return userName ?? 'Unknown User';
  }

  /// Get a widget displaying the user's avatar, handling anonymized users
  static Widget getUserAvatar({
    required String? userId,
    String? profileImageUrl,
    double radius = 20,
  }) {
    if (isAnonymizedUser(userId)) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[700],
        child: Icon(
          Icons.person_off,
          size: radius * 1.2,
          color: Colors.white70,
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF6A0DAD),
      backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
      child: profileImageUrl == null
          ? Icon(
        Icons.person,
        size: radius * 1.2,
        color: Colors.white,
      )
          : null,
    );
  }

  /// Build a user widget with avatar and name for display in lists, etc.
  static Widget buildUserWidget({
    required String? userId,
    required String? userName,
    String? profileImageUrl,
    double avatarRadius = 18,
    TextStyle? nameStyle,
  }) {
    final isAnonymized = isAnonymizedUser(userId);
    final displayedName = getDisplayName(userId, userName);

    return Row(
      children: [
        getUserAvatar(
          userId: userId,
          profileImageUrl: isAnonymized ? null : profileImageUrl,
          radius: avatarRadius,
        ),
        const SizedBox(width: 8),
        Text(
          displayedName,
          style: nameStyle ?? const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}