import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/experience/retreat.dart';
import '../../../models/experience/participant.dart';
import '../../../models/venue.dart';
import '../../../models/facilitator.dart';
import '../../../services/myretreat_service.dart';
import '../../../services/retreat_service.dart';
import '../../../widgets/experience/small_map_widget.dart';
import '../../full_screen_image_viewer.dart';

import '../facilitator_profile_screen.dart';
import 'about_me_screen.dart';
import 'participant_profile_screen.dart';
import 'travel_details_screen.dart';
import 'psychedelic_order_screen.dart';
import 'meq30_screen.dart';
import 'feedback_screen.dart';
import '../../../viewmodels/experience_provider.dart';

class ExperienceDetailScreen extends StatefulWidget {
  final Retreat retreat;
  final Participant participant;

  const ExperienceDetailScreen({
    Key? key,
    required this.retreat,
    required this.participant,
  }) : super(key: key);

  @override
  _ExperienceDetailScreenState createState() => _ExperienceDetailScreenState();
}

class _ExperienceDetailScreenState extends State<ExperienceDetailScreen> {
  late Participant _currentParticipant;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentParticipant = widget.participant;
  }

  @override
  Widget build(BuildContext context) {
    final retreat = widget.retreat;
    final participant = _currentParticipant;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // SliverAppBar with fade gradient and overlays for text clarity.
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            floating: false,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double maxAppBarHeight = 250.0;
                final double minAppBarHeight =
                    kToolbarHeight + MediaQuery.of(context).padding.top;
                final double currentHeight = constraints.biggest.height;
                final double t = ((currentHeight - minAppBarHeight) /
                    (maxAppBarHeight - minAppBarHeight))
                    .clamp(0.0, 1.0);
                final double fadeFactor = 1.0 - t;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Hero image
                    Hero(
                      tag: retreat.cardImageUrl ?? '',
                      child: (retreat.cardImageUrl != null &&
                          retreat.cardImageUrl!.isNotEmpty)
                          ? CachedNetworkImage(
                        imageUrl: retreat.cardImageUrl!,
                        fit: BoxFit.cover,
                      )
                          : Container(
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: Text(
                          'No Image Available',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Gradient overlay (fades as the app bar collapses)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF6A0DAD).withOpacity(fadeFactor),
                            const Color(0xFF3700B3).withOpacity(fadeFactor),
                          ],
                        ),
                      ),
                    ),
                    // Fixed black overlay for text clarity.
                    Container(
                      color: Colors.black.withOpacity(0.25),
                    ),
                    // AppBar title
                    FlexibleSpaceBar(
                      centerTitle: true,
                      titlePadding: const EdgeInsets.only(bottom: 16),
                      title: Text(
                        retreat.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Main content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailedDescriptionMarkdown(retreat),
                    const SizedBox(height: 32),
                    _buildAboutMeSection(retreat, participant),
                    const SizedBox(height: 32),
                    _buildTravelSection(retreat, participant),
                    const SizedBox(height: 32),
                    if (retreat.showMushroomOrder)
                      _buildMushroomsSection(retreat)
                    else if (retreat.showTruffleOrder)
                      _buildTrufflesSection(retreat),
                    const SizedBox(height: 32),
                    _buildSpotifySection(retreat),
                    const SizedBox(height: 32),
                    _buildFacilitatorsSection(retreat.id),
                    const SizedBox(height: 32),
                    _buildFellowNuminautsSection(retreat),
                    const SizedBox(height: 32),
                    _buildMEQAndFeedbackSection(retreat, participant),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── UI HELPERS ─────────────────────────────────────────────────────────────

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

  Widget _buildDetailedDescriptionMarkdown(Retreat retreat) {
    final paragraphs = retreat.detailedDescription;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs
          .map(
            (mdText) => Column(
          children: [
            MarkdownBody(
              data: mdText,
              styleSheet:
              MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: GoogleFonts.roboto(
                  textStyle: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: Colors.black,
                  ),
                ),
                h1: GoogleFonts.roboto(
                  textStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                h2: GoogleFonts.roboto(
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              onTapLink: (text, url, title) => _handleLinkTap(url),
            ),
            const SizedBox(height: 12),
          ],
        ),
      )
          .toList(),
    );
  }

  Widget _buildAboutMeSection(Retreat retreat, Participant participant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('About You'),
        const SizedBox(height: 8),
        Text(
          "It's amazing how strangers often become friends at our retreats. Getting to know each other beforehand can help you feel more connected. Please complete the form below—and share your photo if you’d like.",
          style: GoogleFonts.roboto(
            textStyle:
            const TextStyle(fontSize: 15, height: 1.4, color: Colors.black),
          ),
        ),
        const SizedBox(height: 16),
        _buildWideImageButton(
          assetPath: 'assets/images/myretreat/about_me.png',
          label: 'Complete Profile',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AboutMeScreen(
                  retreatId: retreat.id,
                  participant: participant,
                ),
              ),
            ).then((updatedParticipant) {
              if (updatedParticipant != null &&
                  updatedParticipant is Participant) {
                setState(() {
                  _currentParticipant = updatedParticipant;
                });
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildTravelSection(Retreat retreat, Participant participant) {
    final hasTravelInfo = retreat.travelDescription.isNotEmpty ||
        retreat.retreatAddress.isNotEmpty ||
        retreat.meetingLocation.isNotEmpty ||
        retreat.returnLocation.isNotEmpty ||
        (retreat.latitude != null && retreat.longitude != null);

    if (!hasTravelInfo) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('About Your Travels'),
        for (final mdText in retreat.travelDescription) ...[
          MarkdownBody(
            data: mdText,
            styleSheet:
            MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              p: GoogleFonts.roboto(
                textStyle: const TextStyle(
                    fontSize: 15, height: 1.4, color: Colors.black),
              ),
            ),
            onTapLink: (text, url, title) => _handleLinkTap(url),
          ),
          const SizedBox(height: 12),
        ],
        Card(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (retreat.retreatAddress.isNotEmpty)
                  for (final addressLine in retreat.retreatAddress) ...[
                    MarkdownBody(
                      data: addressLine,
                      styleSheet:
                      MarkdownStyleSheet.fromTheme(Theme.of(context))
                          .copyWith(
                        p: GoogleFonts.roboto(
                          textStyle: const TextStyle(
                              fontSize: 15, height: 1.4, color: Colors.black),
                        ),
                      ),
                      onTapLink: (text, url, title) => _handleLinkTap(url),
                    ),
                    const SizedBox(height: 12),
                  ],
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
                          color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final line in retreat.meetingLocation)
                    Text(
                      line,
                      style: GoogleFonts.roboto(
                        textStyle:
                        const TextStyle(color: Colors.black),
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
                          color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final line in retreat.returnLocation)
                    Text(
                      line,
                      style: GoogleFonts.roboto(
                        textStyle:
                        const TextStyle(color: Colors.black),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (retreat.transportationRequest.isNotEmpty) ...[
          for (final requestLine in retreat.transportationRequest) ...[
            MarkdownBody(
              data: requestLine,
              styleSheet:
              MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: GoogleFonts.roboto(
                  textStyle: const TextStyle(
                    fontSize: 17,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              onTapLink: (text, url, title) => _handleLinkTap(url),
            ),
            const SizedBox(height: 12),
          ],
        ],
        const SizedBox(height: 8),
        _buildWideImageButton(
          assetPath: 'assets/images/myretreat/travel.png',
          label: 'Submit Travel Details',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TravelDetailsScreen(
                  retreatId: retreat.id,
                  userId: participant.userId,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        _buildVenueSection(retreat.venueId),
      ],
    );
  }

  Widget _buildMushroomsSection(Retreat retreat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (retreat.mushroomTitle.isNotEmpty) ...[
          _buildSectionTitle(retreat.mushroomTitle),
          const SizedBox(height: 8),
        ],
        for (final paragraph in retreat.mushroomDescription) ...[
          MarkdownBody(
            data: paragraph,
            styleSheet:
            MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              p: GoogleFonts.roboto(
                textStyle: const TextStyle(
                    fontSize: 15, height: 1.4, color: Colors.black),
              ),
            ),
            onTapLink: (text, url, title) => _handleLinkTap(url),
          ),
          const SizedBox(height: 12),
        ],
        _buildWideImageButton(
          assetPath: 'assets/images/myretreat/order_mushroom.png',
          label: 'Order Mushrooms',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PsychedelicOrderScreen(
                  retreatId: retreat.id,
                  userId: widget.participant.userId,
                  isMushroomOrder: true,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTrufflesSection(Retreat retreat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (retreat.truffleTitle.isNotEmpty) ...[
          _buildSectionTitle(retreat.truffleTitle),
          const SizedBox(height: 8),
        ],
        for (final paragraph in retreat.truffleDescription) ...[
          MarkdownBody(
            data: paragraph,
            styleSheet:
            MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              p: GoogleFonts.roboto(
                textStyle: const TextStyle(
                    fontSize: 15, height: 1.4, color: Colors.black),
              ),
            ),
            onTapLink: (text, url, title) => _handleLinkTap(url),
          ),
          const SizedBox(height: 12),
        ],
        _buildWideImageButton(
          assetPath: 'assets/images/myretreat/order_mushroom.png',
          label: 'Order Truffles',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PsychedelicOrderScreen(
                  retreatId: retreat.id,
                  userId: widget.participant.userId,
                  isMushroomOrder: false,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSpotifySection(Retreat retreat) {
    final links = retreat.spotifyLinks;
    if (links.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Music'),
        Text(
          'Music is a key element of our retreats—designed to evoke emotion, encourage introspection, and enhance your journey. Our curated playlist perfectly complements the retreat atmosphere. Below, discover the soundtrack for your experience.',
          style: GoogleFonts.roboto(
            textStyle:
            const TextStyle(fontSize: 15, height: 1.4, color: Colors.black),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: links.map((link) => _buildSpotifyLinkTile(link)).toList(),
        ),
      ],
    );
  }

  Widget _buildSpotifyLinkTile(String link) {
    return InkWell(
      onTap: () => _launchUrl(link),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1DB954),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FontAwesomeIcons.spotify, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              'Open Playlist',
              style: GoogleFonts.roboto(
                textStyle:
                const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVenueSection(String? venueId) {
    if (venueId == null || venueId.isEmpty) return const SizedBox.shrink();
    final myRetreatService =
    Provider.of<MyRetreatService>(context, listen: false);
    return FutureBuilder<Venue?>(
      future: myRetreatService.getVenueById(venueId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error loading venue: ${snapshot.error}');
        }
        final venue = snapshot.data;
        if (venue == null) {
          return const Text('Venue not found.');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildSectionTitle('About the Venue'),
            const SizedBox(height: 8),
            for (final paragraph in venue.detailedDescription) ...[
              MarkdownBody(
                data: paragraph,
                styleSheet:
                MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: GoogleFonts.roboto(
                    textStyle: const TextStyle(
                        fontSize: 15, height: 1.4, color: Colors.black),
                  ),
                  h1: GoogleFonts.roboto(
                    textStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  h2: GoogleFonts.roboto(
                    textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ),
                onTapLink: (text, url, title) => _handleLinkTap(url),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 16),
            SizedBox(
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFFB4347F)),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 150,
                            height: 120,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFacilitatorsSection(String retreatId) {
    final retreatService =
    Provider.of<RetreatService>(context, listen: false);
    return FutureBuilder<List<Facilitator>>(
      future: retreatService.getFacilitatorsForRetreat(retreatId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text(
            'Error loading facilitators: ${snapshot.error}',
            style: GoogleFonts.roboto(color: Colors.black),
          );
        }
        final facilitators = snapshot.data ?? [];
        if (facilitators.isEmpty) {
          return Text(
            'No facilitators assigned for this retreat.',
            style: GoogleFonts.roboto(fontSize: 15, color: Colors.black),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Facilitators'),
            const SizedBox(height: 8),
            const Text(
              "Numinous Ways' facilitation team comprises experienced mental health professionals who support retreats with compassion and confidentiality. Although they have extensive healthcare backgrounds, they do not provide clinical services; instead, they offer guidance based on personal psychedelic experience to ensure a safe, supportive environment.",
              style: TextStyle(fontSize: 14, color: Colors.black),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: facilitators.length,
                separatorBuilder: (context, index) =>
                const SizedBox(width: 20),
                itemBuilder: (context, index) {
                  final facilitator = facilitators[index];
                  return _buildFacilitatorCard(facilitator);
                },
              ),
            ),
          ],
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
              backgroundImage:
              CachedNetworkImageProvider(facilitator.photoUrl),
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

  Widget _buildFellowNuminautsSection(Retreat retreat) {
    if (!retreat.showFellowNuminauts) return const SizedBox.shrink();
    final retreatService =
    Provider.of<RetreatService>(context, listen: false);

    return FutureBuilder<List<Participant>>(
      future: retreatService.getAllParticipants(retreat.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error loading participants: ${snapshot.error}');
        }
        final participants = snapshot.data ?? [];
        final sharingParticipants =
        participants.where((p) => p.shareBio).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('My Fellow Numinauts'),
            const SizedBox(height: 8),
            const Text(
              "Meet your fellow retreat participants through detailed bios and photos. Connecting early helps build a warm, supportive community.",
              style: TextStyle(fontSize: 15, color: Colors.black),
            ),
            const SizedBox(height: 16),
            sharingParticipants.isEmpty
                ? const Text(
              'No participants have chosen to share their bios yet.',
              style: TextStyle(fontSize: 15, color: Colors.black),
            )
                : SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: sharingParticipants.length,
                separatorBuilder: (context, _) =>
                const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final participant = sharingParticipants[index];
                  return _buildParticipantCard(participant);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildParticipantCard(Participant participant) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ParticipantProfileScreen(participant: participant),
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
              tag: participant.photoUrl ?? participant.userId,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor:
                  const Color(0xFFB4347F).withOpacity(0.1),
                  backgroundImage: participant.photoUrl != null
                      ? CachedNetworkImageProvider(participant.photoUrl!)
                      : null,
                  child: participant.photoUrl == null
                      ? Icon(
                    Icons.person,
                    size: 40,
                    color: const Color(0xFFB4347F).withOpacity(0.5),
                  )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              participant.name,
              style: GoogleFonts.roboto(
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Numinaut',
              style: GoogleFonts.roboto(
                textStyle: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMEQAndFeedbackSection(Retreat retreat, Participant participant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('MEQ-30 & Feedback'),
        const SizedBox(height: 8),
        const Text(
          'Complete the MEQ forms and share your feedback to enhance future retreats. The 30-item MEQ reliably measures mystical dimensions like unity, positive mood, transcendence, and ineffability—helping us better understand transformative experiences.',
          style: TextStyle(fontSize: 14, color: Colors.black),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (retreat.showMEQ)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _buildWideImageButton(
                    assetPath: 'assets/images/myretreat/meq30.png',
                    label: 'MEQ Forms',
                    onPressed: () async {
                      // If the participant already consented, navigate directly.
                      if (participant.meqConsent) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MEQ30Screen(
                              retreatId: retreat.id,
                              participant: participant,
                            ),
                          ),
                        );
                      } else {
                        // Show consent dialog.
                        final accepted = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('MEQ Consent'),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Online Consent Form for Participation in Research\n'
                                        'Title: Mystical Experiences on the Numinous Ways Retreat\n'
                                        'Researcher(s): Numinous Ways\n'
                                        'Contact: info@numinousways.com\n\n'
                                        'Purpose: This research explores mystical experiences during the retreat. Participation is voluntary and you may withdraw at any time.\n\n'
                                        'Key Information:\n'
                                        '• Complete an online MEQ and PPS questionnaire.\n'
                                        '• Your responses are anonymised and will not identify you.\n'
                                        '• You can withdraw at any time without providing a reason.\n\n'
                                        'Consent:\n'
                                        'By checking the box below, you confirm you have read, understood, and agree to participate, and consent to the use of your anonymised data.',
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Decline'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Accept'),
                              ),
                            ],
                          ),
                        );

                        if (accepted == true) {
                          // Use the ExperienceProvider to update MEQ consent.
                          final experienceProvider =
                          Provider.of<ExperienceProvider>(context,
                              listen: false);
                          final updated = await experienceProvider.updateMEQConsent(
                              retreat.id, participant);
                          setState(() {
                            _currentParticipant = updated;
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MEQ30Screen(
                                retreatId: retreat.id,
                                participant: updated,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Consent is required to access the MEQ form.'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ),
            if (retreat.showFeedback)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: _buildWideImageButton(
                    assetPath: 'assets/images/myretreat/feedback.png',
                    label: 'Feedback',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FeedbackScreen(
                            retreatId: retreat.id,
                            userId: participant.userId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildWideImageButton({
    required String assetPath,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: AssetImage(assetPath),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4),
                  BlendMode.darken,
                ),
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.roboto(
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 4,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLinkTap(String? url) async {
    if (url == null) return;
    if (url.startsWith('tel:')) {
      final phoneUri = Uri.parse(url);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showSnackbar("Could not launch phone call");
      }
    } else {
      final linkUri = Uri.parse(url);
      if (await canLaunchUrl(linkUri)) {
        await launchUrl(linkUri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackbar("Could not open link: $url");
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackbar("Cannot open link: $url");
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
