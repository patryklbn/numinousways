import 'package:flutter/material.dart';
import 'package:numinous_way/screens/my_retreat/experience/experience_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/experience/retreat.dart';
import '../../../models/experience/participant.dart'; // Make sure you import Participant here
import '../../../models/facilitator.dart';
import '../../../models/venue.dart';
import '../../../services/retreat_service.dart';
import '../../../services/login_provider.dart';
import '../../../services/myretreat_service.dart';
import '../../../widgets/experience/retreat_card.dart';
import '../../full_screen_image_viewer.dart';
import '../facilitator_profile_screen.dart';
import '../../../widgets/experience/small_map_widget.dart'; // Import your map widget

/// The main screen listing retreats and letting a user select one.
/// We enforce "user must be logged in AND enrolled" to view full details.
class ExperienceMainScreen extends StatefulWidget {
  const ExperienceMainScreen({Key? key}) : super(key: key);

  @override
  _ExperienceMainScreenState createState() => _ExperienceMainScreenState();
}

class _ExperienceMainScreenState extends State<ExperienceMainScreen> {
  late Future<List<Retreat>> _retreatsFuture;
  final RetreatService _retreatService = RetreatService();

  late MyRetreatService _myRetreatService; // for fetching Venue by ID
  Retreat? _selectedRetreat;

  // Map to track which retreat is expanded (showing full shortDescription)
  final Map<String, bool> _expandedRetreats = {};

  // Define color constants
  static const Color appBarColor = Color(0xFFB4347F); // #B4347F
  static const Color accentColor = Color(0xFFD43323); // #d43323
  static const Color errorColor = Color(0xFFD43323); // #d43323

  @override
  void initState() {
    super.initState();
    // Load all active (non-archived) retreats
    _retreatsFuture = _retreatService.fetchActiveRetreats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Once the widget is built, get MyRetreatService from Provider
      _myRetreatService = Provider.of<MyRetreatService>(context, listen: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
        backgroundColor: appBarColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4.0,
      ),
      body: FutureBuilder<List<Retreat>>(
        future: _retreatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading retreats: ${snapshot.error}',
                style: GoogleFonts.roboto(
                  textStyle: TextStyle(
                    color: accentColor,
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
                  textStyle: TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }

          return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: retreats.length,
              itemBuilder: (context, index) {
                final retreat = retreats[index];
                final bool isSelected = (retreat == _selectedRetreat);

                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // The card
                          RetreatCard(
                            retreat: retreat,
                            onTap: () => _onCardTap(retreat),
                          ),

                          // Show details if selected
                          if (isSelected)
                            _buildSelectedRetreatDetails(retreat),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _onCardTap(Retreat retreat) {
    setState(() {
      // Tap again to collapse
      if (_selectedRetreat == retreat) {
        _selectedRetreat = null;
      } else {
        _selectedRetreat = retreat;
      }
    });
  }

  Widget _buildSelectedRetreatDetails(Retreat retreat) {
    final dateFormat = DateFormat('d MMMM');
    final startStr = dateFormat.format(retreat.startDate);
    final endStr = dateFormat.format(retreat.endDate);
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;

    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title: Your Journey Begins Here
          Text(
            'Your Journey Begins Here',
            style: GoogleFonts.roboto(
              textStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Short Description with "Show More/Less" toggle
          _buildShortDescription(retreat),

          const SizedBox(height: 20),

          // Title: Venue
          Text(
            'Venue',
            style: GoogleFonts.roboto(
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildVenueGallery(retreat.venueId),
          const SizedBox(height: 24),

          // Title: Facilitators and Assistants
          Text(
            'Facilitators and Assistants',
            style: GoogleFonts.roboto(
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildFacilitatorsSection(retreat.id),
          const SizedBox(height: 16),

          // Title: Transportation
          Text(
            'Transportation',
            style: GoogleFonts.roboto(
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Transportation Section
          isSmallScreen
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTransportation(retreat),
            ],
          )
              : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTransportation(retreat)),
            ],
          ),

          const SizedBox(height: 16),

          // View Full Details Button
          ElevatedButton(
            onPressed: () => _checkEnrollmentAndNavigate(retreat),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
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
            child: const Text('View Full Details'),
          ),
        ],
      ),
    );
  }

  /// Builds a truncated or full short description depending on the user's toggle.
  Widget _buildShortDescription(Retreat retreat) {
    // Join paragraphs into one string
    final shortDesc = retreat.shortDescription.join('\n\n');

    // Check if retreat is expanded in our map
    final isExpanded = _expandedRetreats[retreat.id] ?? false;

    // Choose a character limit for truncation
    const maxChars = 300;

    // If the text is shorter than [maxChars], just show it all
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

    // Otherwise, show truncated or full text + "Show more / Show less" button
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
                color: accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Display the Venue gallery
  Widget _buildVenueGallery(String? venueId) {
    if (venueId == null || venueId.isEmpty) {
      return Text(
        "No venue assigned for this retreat.",
        style: GoogleFonts.roboto(
          textStyle: TextStyle(
            color: accentColor,
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
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
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
                color: accentColor,
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
                color: accentColor,
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
                          valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 150,
                        height: 120,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.error,
                          color: accentColor,
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

  /// Display the list of facilitators
  Widget _buildFacilitatorsSection(String retreatId) {
    return FutureBuilder<List<Facilitator>>(
      future: _retreatService.getFacilitatorsForRetreat(retreatId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
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
                color: accentColor,
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
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: facilitators.length,
            separatorBuilder: (context, index) => const SizedBox(width: 20),
            itemBuilder: (context, index) {
              final facilitator = facilitators[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FacilitatorProfileScreen(
                        facilitator: facilitator,
                      ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Hero(
                      tag: facilitator.photoUrl,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: CachedNetworkImageProvider(
                          facilitator.photoUrl,
                        ),
                      ),
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
              );
            },
          ),
        );
      },
    );
  }

  /// Display a small map or other info for transportation
  Widget _buildTransportation(Retreat retreat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show a map if lat/long present
        if (retreat.latitude != null && retreat.longitude != null)
          SmallMapWidget(
            latitude: retreat.latitude!,
            longitude: retreat.longitude!,
            zoomLevel: 11,
          )
        else
          const Text("No map available: Missing coordinates."),
      ],
    );
  }

  /// Check if user is logged in + is enrolled, then fetch participant & navigate
  Future<void> _checkEnrollmentAndNavigate(Retreat retreat) async {
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final userId = loginProvider.userId;

    // 1) Must be logged in
    if (userId == null) {
      _showDialog('Please log in first to view retreat details.');
      return;
    }

    // 2) Must be enrolled in this retreat
    final isEnrolled = await _retreatService.isUserEnrolled(retreat.id, userId);
    if (!isEnrolled) {
      _showDialog('You must be enrolled to view full retreat details.');
      return;
    }

    // 3) Fetch participant doc for this user
    final participant = await _retreatService.getParticipant(retreat.id, userId);
    if (participant == null) {
      _showDialog('Could not find your participant record. Please contact support.');
      return;
    }

    // 4) Navigate to detail screen, providing both retreat & participant
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
              color: accentColor,
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
                  color: accentColor,
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
