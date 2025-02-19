import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '/../models/experience/participant.dart';

class ParticipantProfileScreen extends StatelessWidget {
  final Participant participant;

  const ParticipantProfileScreen({
    Key? key,
    required this.participant,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // White background as before.
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Set the backgroundColor to transparent and use flexibleSpace for the gradient.
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A0DAD), Color(0xFF3700B3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          participant.name,
          style: GoogleFonts.roboto(
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          // All content left-aligned.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Participant Image.
              Center(
                child: participant.photoUrl != null
                    ? Hero(
                  tag: participant.photoUrl!,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage:
                    CachedNetworkImageProvider(participant.photoUrl!),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    : CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Participant Name (centered for emphasis).
              Center(
                child: Text(
                  participant.name,
                  style: GoogleFonts.roboto(
                    textStyle: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              // Display profile fields only if they are not empty.
              _buildProfileField("SHARE A BIT ABOUT YOURSELF", participant.aboutYourself),
              _buildProfileField("HOW WOULD YOU LIKE PEOPLE TO CALL YOU", participant.nickname),
              _buildProfileField("PREFERRED PRONOUNS", participant.pronouns),
              _buildProfileField("WHAT KIND OF WORK HAVE YOU DONE/DO YOU DO", participant.work),
              _buildProfileField("WHAT KIND OF THINGS DO YOU ENJOY DOING IN YOUR SPARE TIME", participant.hobbies),
              _buildProfileField("WHAT, IF ANY, PSYCHEDELIC EXPERIENCE DO YOU HAVE", participant.psychedelicExperience),
              _buildProfileField("WHAT ELSE WOULD BE HELPFUL FOR PEOPLE TO KNOW ABOUT YOU", participant.additionalInfo),
              _buildProfileField("WHAT ANIMAL, IF ANY, DO YOU FEEL MOST CONNECTED TO/DO YOU FEEL BEST REPRESENTS YOU", participant.favoriteAnimal),
              _buildProfileField("WHAT’S YOUR EARLIEST MEMORY", participant.earliestMemory),
              _buildProfileField("TELL US ABOUT SOMETHING YOU LOVE", participant.somethingYouLove),
              _buildProfileField("TELL US ABOUT SOMETHING WHICH YOU FIND DIFFICULT", participant.somethingDifficult),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    // Hide the field if the value is empty.
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 26.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.roboto(
              textStyle: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.6,
              ),
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }
}
