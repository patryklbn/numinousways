import 'package:flutter/material.dart';
import 'package:numinous_ways/screens/my_retreat/experience/experience_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/experience/retreat.dart';
import '../../../models/facilitator.dart';
import '../../../models/venue.dart';
import '../../../services/retreat_service.dart';
import '../../../services/login_provider.dart';
import '../../../services/myretreat_service.dart';
import '../../../widgets/experience/retreat_card.dart';
import '../facilitator_profile_screen.dart';
import '../../../widgets/experience/small_map_widget.dart';
import '../../../viewmodels/experience_provider.dart';

class ExperienceMainScreen extends StatefulWidget {
  const ExperienceMainScreen({Key? key}) : super(key: key);

  @override
  _ExperienceMainScreenState createState() => _ExperienceMainScreenState();
}

class _ExperienceMainScreenState extends State<ExperienceMainScreen> with SingleTickerProviderStateMixin {
  late Future<List<Retreat>> _retreatsFuture;
  final RetreatService _retreatService = RetreatService();
  late MyRetreatService _myRetreatService;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  Retreat? _selectedRetreat;
  PageController? _galleryPageController;
  final ScrollController _horizontalScrollController = ScrollController();

  // Scroll indicator state variables
  bool _showScrollIndicator = true;
  bool _userHasScrolled = false;

  // For toggling "Show more / Show less" in each retreat's shortDescription
  final Map<String, bool> _expandedRetreats = {};

  // Gradient colors for your AppBar
  static const Color gradientColor1 = Color(0xFF6A0DAD);
  static const Color gradientColor2 = Color(0xFF3700B3);

  @override
  void initState() {
    super.initState();
    // Setup animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    // Add scroll listener to hide indicator once user has scrolled
    _horizontalScrollController.addListener(() {
      if (_horizontalScrollController.offset > 10 && !_userHasScrolled) {
        setState(() {
          _userHasScrolled = true;
          _showScrollIndicator = false;
        });
      }
    });

    // Fetch all active (non-archived) retreats
    _retreatsFuture = _retreatService.fetchActiveRetreats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _myRetreatService = Provider.of<MyRetreatService>(context, listen: false);

      // Auto-hide scroll indicator after 5 seconds even if user hasn't scrolled
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _showScrollIndicator = false;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _galleryPageController?.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Add horizontal swipe detection for going back
      onHorizontalDragEnd: (details) {
        // If the swipe is from left to right with sufficient velocity
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          // Check if we can pop this route
          if (Navigator.of(context).canPop()) {
            // Pop the route to go back
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        // Gradient AppBar
        appBar: AppBar(
          centerTitle: true,
          title: FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
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
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
// Title area with just the scroll indicator when needed
                    if (retreats.length > 1 && _showScrollIndicator)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            _buildScrollIndicator(),
                          ],
                        ),
                      ),

                    // 1) Horizontal list of retreat cards
                    _buildHorizontalRetreatList(retreats),
                    const SizedBox(height: 24),

                    // 2) Detail section for the currently selected retreat
                    _buildSelectedRetreatDetails(_selectedRetreat!),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds the horizontal scroll indicator
  Widget _buildScrollIndicator() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Row(
            children: [
              Icon(
                Icons.swipe_right_alt,
                color: gradientColor2.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                'Swipe to see more',
                style: GoogleFonts.roboto(
                  textStyle: TextStyle(
                    fontSize: 13,
                    color: gradientColor2.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds a horizontal-scrolling list of retreat cards
  Widget _buildHorizontalRetreatList(List<Retreat> retreats) {
    return Column(
      children: [
        SizedBox(
          height: 377,
          child: ListView.separated(
            controller: _horizontalScrollController,
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
        ),
        // Pagination dots for indicating position
        if (retreats.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: _buildPaginationDots(retreats),
          ),
      ],
    );
  }

  /// Build pagination dots that indicate which card is visible
  Widget _buildPaginationDots(List<Retreat> retreats) {
    // Find index of currently selected retreat
    final int selectedIndex = retreats.indexWhere((retreat) => retreat.id == _selectedRetreat?.id);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(retreats.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: index == selectedIndex ? 24 : 8,
          decoration: BoxDecoration(
            color: index == selectedIndex
                ? gradientColor2
                : Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  /// Detail section for the selected retreat
  Widget _buildSelectedRetreatDetails(Retreat retreat) {
    final dateFormat = DateFormat('d MMMM');
    final startStr = dateFormat.format(retreat.startDate);
    final endStr = dateFormat.format(retreat.endDate);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.2),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Column(
        key: ValueKey<String>(retreat.id), // Important for animation
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
      ),
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
        AnimatedCrossFade(
          firstChild: Text(
            truncatedText,
            style: GoogleFonts.roboto(
              textStyle: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.6,
              ),
            ),
          ),
          secondChild: Text(
            shortDesc,
            style: GoogleFonts.roboto(
              textStyle: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.6,
              ),
            ),
          ),
          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
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

  /// Enhanced gallery viewer with swipe gestures
  void _showGallery(BuildContext context, List<String> images, int initialIndex, String tag) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
                Navigator.of(context).pop();
              }
            },
            child: Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black.withOpacity(0.5),
                elevation: 0,
                title: StreamBuilder<int>(
                  stream: Stream.periodic(Duration.zero, (i) => i).asyncMap((_) async {
                    await Future.delayed(Duration.zero);
                    return _galleryPageController?.page?.round() ?? initialIndex;
                  }),
                  initialData: initialIndex,
                  builder: (context, snapshot) {
                    final currentIndex = snapshot.data ?? initialIndex;
                    return Text(
                      'Image ${currentIndex + 1}/${images.length}',
                      style: const TextStyle(color: Colors.white),
                    );
                  },
                ),
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              body: PageView.builder(
                controller: _galleryPageController = PageController(initialPage: initialIndex),
                itemCount: images.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (ctx, index) {
                  return Hero(
                    tag: '$tag-$index',
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: CachedNetworkImage(
                        imageUrl: images[index],
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.error,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.2);
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end);
          final offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
      ),
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
                  _showGallery(context, venue.images, index, 'venue-$venueId');
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
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: facilitators.length,
            itemBuilder: (context, index) {
              final facilitator = facilitators[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 500),
                child: SlideAnimation(
                  horizontalOffset: 50.0,
                  child: FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: _buildFacilitatorCard(facilitator),
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

  Widget _buildFacilitatorCard(Facilitator facilitator) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => FacilitatorProfileScreen(facilitator: facilitator),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 0.2);
              const end = Offset.zero;
              final tween = Tween(begin: begin, end: end);
              final offsetAnimation = animation.drive(tween);

              return SlideTransition(
                position: offsetAnimation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
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
            Hero(
              tag: 'facilitator-${facilitator.id}',
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[200],
                backgroundImage: CachedNetworkImageProvider(facilitator.photoUrl),
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
      ),
    );
  }

  // -------------------------------
  // ENHANCED TRANSPORTATION (LOCATION) SECTION
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
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.1),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (retreat.latitude != null && retreat.longitude != null) ...[
                  SmallMapWidget(
                    latitude: retreat.latitude!,
                    longitude: retreat.longitude!,
                    zoomLevel: 11,
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (retreat.meetingLocation.isNotEmpty) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.meeting_room, color: gradientColor2, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                  ...retreat.meetingLocation.map((line) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      line,
                                      style: GoogleFonts.roboto(
                                        textStyle: TextStyle(
                                          color: Colors.grey[800],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (retreat.returnLocation.isNotEmpty) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.directions_walk, color: gradientColor2, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                  ...retreat.returnLocation.map((line) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      line,
                                      style: GoogleFonts.roboto(
                                        textStyle: TextStyle(
                                          color: Colors.grey[800],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
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
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [gradientColor1, gradientColor2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColor1.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _navigateToFullDetails(retreat),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: GoogleFonts.roboto(
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'View Full Details',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
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

    // Use PageRouteBuilder for smooth transition
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ExperienceDetailScreen(
          retreat: retreat,
          participant: participant,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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