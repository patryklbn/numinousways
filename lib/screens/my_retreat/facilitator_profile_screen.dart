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
    // Improved text processing
    // 1. Replace literal \n with actual newlines
    // 2. Trim each paragraph to remove extra spaces
    // 3. Handle any potential double spaces within paragraphs
    String processedDescription = (facilitator.description ?? '').replaceAll('\\n', '\n');

    // Split into paragraphs and process each one
    final List<String> paragraphs = processedDescription
        .split('\n\n')
        .map((paragraph) => paragraph.trim().replaceAll(RegExp(r'\s{2,}'), ' '))
        .toList();

    return Scaffold(
      // AppBar with centered title for both iOS and Android
      appBar: AppBar(
        title: Text(
          facilitator.name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true, // This forces the title to be centered on all platforms
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
                  // Facilitator Image with enhanced shadow
                  Hero(
                    tag: facilitator.photoUrl, // Unique tag
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 70, // Slightly larger
                        backgroundColor: Colors.white,
                        backgroundImage: CachedNetworkImageProvider(facilitator.photoUrl),
                      ),
                    ),
                  ),
                  SizedBox(height: 24), // Increased spacing

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

                  // Facilitator Role with subtle divider
                  Column(
                    children: [
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
                      SizedBox(height: 16),
                      Container(
                        width: 50,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Color(0xFF1A192E).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 28), // Increased spacing

                  // Facilitator Description (Paragraphs) - Improved styling
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: paragraphs.map((paragraph) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20.0), // Increased bottom padding
                        child: Text(
                          paragraph,
                          textAlign: TextAlign.justify,
                          style: GoogleFonts.openSans(
                            textStyle: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                              height: 1.5, // Slightly adjusted line height
                              letterSpacing: 0.2, // Slight letter spacing for readability
                              wordSpacing: 0.5, // Improved word spacing
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  // Added some bottom padding for better scrolling experience
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}