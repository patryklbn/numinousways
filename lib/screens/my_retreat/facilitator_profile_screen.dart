import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/facilitator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class FacilitatorProfileScreen extends StatelessWidget {
  final Facilitator facilitator;

  const FacilitatorProfileScreen({
    Key? key,
    required this.facilitator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Safely handle null description and replace literal \n with actual newlines
    final description = (facilitator.description ?? '').replaceAll('\\n', '\n');

    // Split the description into paragraphs
    final paragraphs = description.split('\n\n');

    return Scaffold(
      // Static AppBar Color
      appBar: AppBar(
        title: Text(
          facilitator.name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF1A192E), // Static color #1a192e
        elevation: 2,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height, // Ensure full screen coverage
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFAF9F6), Color(0xFFF5F5F5)], // Off-white gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Facilitator Image
                  Hero(
                    tag: facilitator.photoUrl, // Unique tag
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage: CachedNetworkImageProvider(facilitator.photoUrl),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Facilitator Name
                  Text(
                    facilitator.name,
                    style: GoogleFonts.lato(
                      textStyle: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),

                  // Facilitator Role
                  Text(
                    facilitator.role,
                    style: GoogleFonts.lato(
                      textStyle: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),

                  // Facilitator Description (Paragraphs)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: paragraphs.map((paragraph) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          paragraph,
                          textAlign: TextAlign.justify,
                          style: GoogleFonts.openSans(
                            textStyle: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                              height: 1.6, // Line height
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
