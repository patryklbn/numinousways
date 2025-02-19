import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:numinous_way/screens/my_retreat/experience/experience_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/experience/retreat.dart';
import '../../../models/experience/participant.dart';
import '../../../models/facilitator.dart';
import '../../../models/venue.dart';
import '../../../services/retreat_service.dart';
import '../../../services/login_provider.dart';
import '../../../services/myretreat_service.dart';
import '../../../widgets/experience/retreat_card.dart';
import '../../full_screen_image_viewer.dart';
import '../facilitator_profile_screen.dart';
import '../../../widgets/experience/small_map_widget.dart';
import '../../../viewmodels/experience_provider.dart'; // Import the provider

class ExperienceMainScreen extends StatefulWidget {
  const ExperienceMainScreen({Key? key}) : super(key: key);

  @override
  _ExperienceMainScreenState createState() => _ExperienceMainScreenState();
}

class _ExperienceMainScreenState extends State<ExperienceMainScreen> {
  late Future<List<Retreat>> _retreatsFuture;
  final RetreatService _retreatService = RetreatService();
  late MyRetreatService _myRetreatService;

  Retreat? _selectedRetreat;

  // For toggling "Show more / Show less" in each retreat's shortDescription
  final Map<String, bool> _expandedRetreats = {};

  // Gradient colors for your AppBar
  static const Color gradientColor1 = Color(0xFF6A0DAD);
  static const Color gradientColor2 = Color(0xFF3700B3);

  @override
  void initState() {
    super.initState();
    // Fetch all active (non-archived) retreats
    _retreatsFuture = _retreatService.fetchActiveRetreats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _myRetreatService = Provider.of<MyRetreatService>(context, listen: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Gradient AppBar
      appBar: AppBar(
        title: Text(
          'Experience',
          style: GoogleFonts.roboto(
            textStyle: const TextStyle(
              color: Colors.white,
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
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [gradientColor1, gradientColor2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4.0,
      ),
      body: FutureBuilder<List<Retreat>>(
        future: _retreatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(gradientColor2),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading retreats: ${snapshot.error}',
                style: GoogleFonts.roboto(
                  textStyle: const TextStyle(
                    color: gradientColor2,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }

          final retreats = snapshot.data ?? [];
          if (retreats.isEmpty) {
            return Center(
              child: Text(
                'No retreats available.',
                style: GoogleFonts.roboto(
                  textStyle: const TextStyle(
                    color: gradientColor2,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }

          // If none is selected yet, pick the first
          _selectedRetreat ??= retreats.first;

          // Wrap everything in a scrollable Column
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1) Horizontal list of retreat cards
                _buildHorizontalRetreatList(retreats),
                const SizedBox(height: 24),

                // 2) Detail section for the currently selected retreat
                _buildSelectedRetreatDetails(_selectedRetreat!),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds a horizontal-scrolling list of retreat cards
  Widget _buildHorizontalRetreatList(List<Retreat> retreats) {
    return SizedBox(
      height: 377,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 1),
        separatorBuilder: (context, index) => const SizedBox(width: 1),
        itemCount: retreats.length,
        itemBuilder: (context, index) {
          final retreat = retreats[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              horizontalOffset: 50.0,
              child: FadeInAnimation(
                child: SizedBox(
                  width: 335,
                  child: RetreatCard(
                    retreat: retreat,
                    onTap: () {
                      setState(() {
                        _selectedRetreat = retreat;
                      });
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Detail section for the selected retreat
  Widget _buildSelectedRetreatDetails(Retreat retreat) {
    final dateFormat = DateFormat('d MMMM');
    final startStr = dateFormat.format(retreat.startDate);
    final endStr = dateFormat.format(retreat.endDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Your Journey Begins Here'),
        const SizedBox(height: 8),
        _buildShortDescription(retreat),
        const SizedBox(height: 20),
        _buildSectionTitle('Venue'),
        const SizedBox(height: 8),
        _buildVenueGallery(retreat.venueId),
        const SizedBox(height: 24),
        _buildSectionTitle('Facilitators and Assistants'),
        const SizedBox(height: 8),
        _buildFacilitatorsSection(retreat.id),
        const SizedBox(height: 24),
        // Transportation section now rebranded as "Location"
        _buildTravelSection(retreat),
        const SizedBox(height: 24),
        _buildEnrollmentSection(retreat),
      ],
    );
  }

  /// Header styling
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.roboto(
        textStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
          letterSpacing: 0.5,
          shadows: [
            Shadow(
              offset: Offset(0, 1),
              blurRadius: 2.0,
              color: Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  /// Short description with a "Show more / Show less" toggle
  Widget _buildShortDescription(Retreat retreat) {
    final shortDesc = retreat.shortDescription.join('\n\n');
    final isExpanded = _expandedRetreats[retreat.id] ?? false;
    const maxChars = 300;

    if (shortDesc.length <= maxChars) {
      return Text(
        shortDesc,
        style: GoogleFonts.roboto(
          textStyle: TextStyle(
            fontSize: 16,
            color: Colors.grey[800],
            height: 1.6,
          ),
        ),
      );
    }

    final truncatedText = shortDesc.substring(0, maxChars) + '...';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isExpanded ? shortDesc : truncatedText,
          style: GoogleFonts.roboto(
            textStyle: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () {
            setState(() {
              _expandedRetreats[retreat.id] = !isExpanded;
            });
          },
          child: Text(
            isExpanded ? 'Show less' : 'Show more',
            style: GoogleFonts.roboto(
              textStyle: TextStyle(
                fontSize: 14,
                color: gradientColor2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Displays venue images or a placeholder
  Widget _buildVenueGallery(String? venueId) {
    if (venueId == null || venueId.isEmpty) {
      return Text(
        "No venue assigned for this retreat.",
        style: GoogleFonts.roboto(
          textStyle: const TextStyle(
            color: gradientColor2,
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    return FutureBuilder<Venue?>(
      future: _myRetreatService.getVenueById(venueId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(gradientColor2),
              ),
              const SizedBox(width: 8),
              Text(
                "Loading venue...",
                style: GoogleFonts.roboto(
                  textStyle: TextStyle(
                    color: Colors.grey[800],
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          );
        }
        if (snapshot.hasError) {
          return Text(
            "Error: ${snapshot.error}",
            style: GoogleFonts.roboto(
              textStyle: TextStyle(
                color: gradientColor2,
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
        final venue = snapshot.data;
        if (venue == null) {
          return Text(
            "Venue not found for ID: $venueId",
            style: GoogleFonts.roboto(
              textStyle: TextStyle(
                color: gradientColor2,
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
        if (venue.images.isEmpty) {
          return Text(
            "No images for this venue.",
            style: GoogleFonts.roboto(
              textStyle: TextStyle(
                color: Colors.grey[800],
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
        return SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: venue.images.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final imageUrl = venue.images[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImageViewer(
                        imageUrl: imageUrl,
                        tag: 'venue-$venueId-$index',
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: 'venue-$venueId-$index',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 150,
                      height: 120,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(gradientColor2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 150,
                        height: 120,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.error,
                          color: gradientColor2,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Facilitators as cards
  Widget _buildFacilitatorsSection(String retreatId) {
    return FutureBuilder<List<Facilitator>>(
      future: _retreatService.getFacilitatorsForRetreat(retreatId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(gradientColor2),
              ),
              const SizedBox(width: 8),
              Text(
                'Loading facilitators...',
                style: GoogleFonts.roboto(
                  textStyle: TextStyle(
                    color: Colors.grey[800],
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          );
        }
        if (snapshot.hasError) {
          return Text(
            'Error loading facilitators: ${snapshot.error}',
            style: GoogleFonts.roboto(
              textStyle: TextStyle(
                color: gradientColor2,
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
        final facilitators = snapshot.data ?? [];
        if (facilitators.isEmpty) {
          return Text(
            'No facilitators assigned for this retreat.',
            style: GoogleFonts.roboto(
              textStyle: TextStyle(
                color: Colors.grey[800],
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
        return SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: facilitators.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final facilitator = facilitators[index];
              return _buildFacilitatorCard(facilitator);
            },
          ),
        );
      },
    );
  }

  Widget _buildFacilitatorCard(Facilitator facilitator) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FacilitatorProfileScreen(facilitator: facilitator),
          ),
        );
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[100]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[200],
              backgroundImage: CachedNetworkImageProvider(facilitator.photoUrl),
            ),
            const SizedBox(height: 8),
            Text(
              facilitator.name,
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              facilitator.role,
              style: GoogleFonts.roboto(
                textStyle: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------
  // TRANSPORTATION (LOCATION) SECTION
  // -------------------------------
  Widget _buildTravelSection(Retreat retreat) {
    final hasTravelInfo = retreat.meetingLocation.isNotEmpty ||
        retreat.returnLocation.isNotEmpty ||
        (retreat.latitude != null && retreat.longitude != null);

    if (!hasTravelInfo) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Location'),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (retreat.latitude != null && retreat.longitude != null) ...[
                  SmallMapWidget(
                    latitude: retreat.latitude!,
                    longitude: retreat.longitude!,
                    zoomLevel: 11,
                  ),
                  const SizedBox(height: 16),
                ],
                if (retreat.meetingLocation.isNotEmpty) ...[
                  Text(
                    'Meeting Location:',
                    style: GoogleFonts.roboto(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final line in retreat.meetingLocation)
                    Text(
                      line,
                      style: GoogleFonts.roboto(
                        textStyle: const TextStyle(color: Colors.black),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
                if (retreat.returnLocation.isNotEmpty) ...[
                  Text(
                    'Return Location:',
                    style: GoogleFonts.roboto(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final line in retreat.returnLocation)
                    Text(
                      line,
                      style: GoogleFonts.roboto(
                        textStyle: const TextStyle(color: Colors.black),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------
  // "ALREADY SIGNED UP?" SECTION
  // -------------------------------
  Widget _buildEnrollmentSection(Retreat retreat) {
    final experienceProvider = Provider.of<ExperienceProvider>(context, listen: false);
    return FutureBuilder<bool>(
      future: experienceProvider.checkEnrollment(retreat.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final isEnrolled = snapshot.data ?? false;
        if (!isEnrolled) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Already Signed Up?'),
            const SizedBox(height: 8),
            Text(
              "If you're already enrolled for this retreat, click below for more detailed information and access to important forms.",
              style: GoogleFonts.roboto(
                textStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [gradientColor1, gradientColor2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: () => _navigateToFullDetails(retreat),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  child: const Text(
                    'View Full Details',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // -------------------------------
  // NAVIGATION & ERROR HANDLING HELPERS
  // -------------------------------
  Future<void> _navigateToFullDetails(Retreat retreat) async {
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final experienceProvider = Provider.of<ExperienceProvider>(context, listen: false);
    final userId = loginProvider.userId;
    if (userId == null) {
      _showDialog('Please log in first to view retreat details.');
      return;
    }

    final participant = await experienceProvider.fetchParticipant(retreat.id);
    if (participant == null) {
      _showDialog('Could not find your participant record. Please contact support.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExperienceDetailScreen(
          retreat: retreat,
          participant: participant,
        ),
      ),
    );
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Access Restricted',
          style: GoogleFonts.roboto(
            textStyle: TextStyle(
              color: gradientColor2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.roboto(
            textStyle: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.roboto(
                textStyle: TextStyle(
                  color: gradientColor2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
