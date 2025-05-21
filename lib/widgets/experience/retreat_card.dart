// lib/widgets/experience/retreat_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../../models/experience/retreat.dart';

class RetreatCard extends StatelessWidget {
  final Retreat retreat;
  final VoidCallback onTap;

  const RetreatCard({
    Key? key,
    required this.retreat,
    required this.onTap,
  }) : super(key: key);

  // Define color constants
  static const Color primaryColor = Color(0xFF1E1E1E);
  static const Color accentColor = Color(0xFFD43323); // Red color
  static const Color subtitleColor = Color(0xFFA0A0A0); // Grey color
  static const Color iconBackgroundColor = Colors.white; // Background for icons
  static const Color detailsBackgroundColor = Colors.white; // Clean white background

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Retreat Image with Gradient Overlay
            if (retreat.cardImageUrl != null && retreat.cardImageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: retreat.cardImageUrl!,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 220,
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 220,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.error,
                          color: accentColor,
                          size: 40,
                        ),
                      ),
                    ),
                    // Gradient Overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    // Retreat Title on Image
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Text(
                        retreat.title,
                        style: GoogleFonts.lato(
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2.0,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: detailsBackgroundColor,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location
                  Row(
                    children: [
                      _buildIconWithBackground(FontAwesomeIcons.mapMarkerAlt),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          retreat.location,
                          style: GoogleFonts.lato(
                            textStyle: const TextStyle(
                              color: primaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Dates
                  Row(
                    children: [
                      _buildIconWithBackground(FontAwesomeIcons.calendarAlt),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_formatDate(retreat.startDate)} - ${_formatDate(retreat.endDate)}',
                          style: GoogleFonts.lato(
                            textStyle: const TextStyle(
                              color: primaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Cost - Only show if cost is greater than 0, otherwise show "Members Only"
                  Row(
                    children: [
                      _buildIconWithBackground(
                          retreat.cost > 0 ? FontAwesomeIcons.poundSign : FontAwesomeIcons.userLock
                      ),
                      const SizedBox(width: 8),
                      Text(
                        retreat.cost > 0
                            ? '£${retreat.cost}'
                            : 'Students Only',
                        style: GoogleFonts.lato(
                          textStyle: TextStyle(
                            color: retreat.cost > 0 ? primaryColor : accentColor,
                            fontSize: 14,
                            fontWeight: retreat.cost > 0 ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method to format DateTime objects
  String _formatDate(DateTime date) {
    final formatter = DateFormat('d MMM yyyy');
    return formatter.format(date);
  }

  /// Reusable widget for icons with background
  Widget _buildIconWithBackground(IconData iconData) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: iconBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2), // Shadow position
          ),
        ],
      ),
      child: Icon(
        iconData,
        size: 16,
        color: accentColor, // Icon color remains accentColor
      ),
    );
  }
}