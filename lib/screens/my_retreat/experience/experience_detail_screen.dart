import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';


import '../../../models/experience/retreat.dart';
import '../../../models/experience/participant.dart';
import '../../../models/venue.dart';
import '../../../services/myretreat_service.dart';
import '../../../services/login_provider.dart';
import '../../../services/retreat_service.dart';
import '../../../widgets/experience/small_map_widget.dart';
import '../../full_screen_image_viewer.dart';
import 'about_me_screen.dart';
import 'participant_profile_screen.dart';
import 'travel_details_screen.dart'; // For "Submit Travel Details" button

import './psychedelic_order_screen.dart';

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
  bool _meqConsentDialogAccepted = false;
  late Participant _currentParticipant; // Local copy to update dynamically

  @override
  void initState() {
    super.initState();
    _currentParticipant = widget.participant;
  }

  @override
  Widget build(BuildContext context) {
    final retreat = widget.retreat;
    final participant = _currentParticipant; // Reflect changes from AboutMeScreen

    return Scaffold(
      appBar: AppBar(
        title: Text(retreat.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1) Title
            Text(
              'Your Journey',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // 2) Detailed description
            _buildDetailedDescriptionMarkdown(retreat),
            const SizedBox(height: 24),

            // 3) "Complete About Me"
            _buildMainActionButtons(retreat, participant),
            const SizedBox(height: 24),

            // 4) About Your Travels
            _buildTravelSection(retreat, participant),
            const SizedBox(height: 24),

            // 5) If showMushroomOrder is true -> show a Mushrooms Section
            if (retreat.showMushroomOrder) _buildMushroomsSection(retreat),
            const SizedBox(height: 24),

            // 6) If showTruffleOrder is true -> show a Truffles Section
            if (retreat.showTruffleOrder) _buildTrufflesSection(retreat),
            const SizedBox(height: 24),

            // 7) Spotify
            _buildSpotifySection(retreat),
            const SizedBox(height: 24),

            // 8) Fellow Numinauts
            if (retreat.showFellowNuminauts)
              _buildFellowNuminautsSection(retreat),
            const SizedBox(height: 24),

            // 9) MEQ & Feedback
            _buildMEQAndFeedbackSection(retreat, participant),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1) Detailed Description
  Widget _buildDetailedDescriptionMarkdown(Retreat retreat) {
    final paragraphs = retreat.detailedDescription; // array of Markdown strings

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final mdText in paragraphs) ...[
          MarkdownBody(
            data: mdText,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                height: 1.4,
              ),
              h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            onTapLink: (text, url, title) => _handleLinkTap(url),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2) Main action buttons
  Widget _buildMainActionButtons(Retreat retreat, Participant participant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: () {
            // Navigate to AboutMeScreen and await its result.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AboutMeScreen(
                  retreatId: retreat.id,
                  participant: participant,
                ),
              ),
            ).then((updatedParticipant) {
              if (updatedParticipant != null && updatedParticipant is Participant) {
                setState(() {
                  _currentParticipant = updatedParticipant;
                });
              }
            });
          },
          child: const Text('Complete About Me'),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3) About Your Travels
  Widget _buildTravelSection(Retreat retreat, Participant participant) {
    final hasTravel = retreat.travelDescription.isNotEmpty ||
        retreat.retreatAddress.isNotEmpty ||
        retreat.meetingLocation.isNotEmpty ||
        retreat.returnLocation.isNotEmpty ||
        (retreat.latitude != null && retreat.longitude != null);

    if (!hasTravel) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'About your travels',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // travelDescription
        for (final mdText in retreat.travelDescription) ...[
          MarkdownBody(
            data: mdText,
            styleSheet:
            MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                height: 1.4,
              ),
              h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            onTapLink: (text, url, title) => _handleLinkTap(url),
          ),
          const SizedBox(height: 12),
        ],

        // retreatAddress
        if (retreat.retreatAddress.isNotEmpty) ...[
          for (final addressLine in retreat.retreatAddress) ...[
            MarkdownBody(
              data: addressLine,
              styleSheet:
              MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  height: 1.4,
                ),
                h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              onTapLink: (text, url, title) => _handleLinkTap(url),
            ),
            const SizedBox(height: 12),
          ],
        ],

        // Map
        if (retreat.latitude != null && retreat.longitude != null) ...[
          const SizedBox(height: 8),
          SmallMapWidget(
            latitude: retreat.latitude!,
            longitude: retreat.longitude!,
            zoomLevel: 11,
          ),
          const SizedBox(height: 16),
        ],

        // Meeting Location
        if (retreat.meetingLocation.isNotEmpty) ...[
          const Text(
            'Meeting Location:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          for (final line in retreat.meetingLocation) Text(line),
          const SizedBox(height: 12),
        ],

        // Return Location
        if (retreat.returnLocation.isNotEmpty) ...[
          const Text(
            'Return Location:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          for (final line in retreat.returnLocation) Text(line),
          const SizedBox(height: 12),
        ],

        // Transportation Request
        if (retreat.transportationRequest.isNotEmpty) ...[
          for (final requestLine in retreat.transportationRequest) ...[
            MarkdownBody(
              data: requestLine,
              styleSheet:
              MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 17,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
                h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              onTapLink: (text, url, title) => _handleLinkTap(url),
            ),
            const SizedBox(height: 12),
          ],
        ],

        // Submit Travel Details button
        ElevatedButton(
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
          child: const Text('Submit Travel Details'),
        ),

        const SizedBox(height: 24),

        // About the Venue
        _buildVenueSection(retreat.venueId),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4) Mushroom Section (show if showMushroomOrder == true)
  Widget _buildMushroomsSection(Retreat retreat) {
    // Title & paragraphs
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // If there's a mushroomTitle (bold markdown)
        if (retreat.mushroomTitle.isNotEmpty) ...[
          MarkdownBody(
            data: retreat.mushroomTitle,
            styleSheet:
            MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
            onTapLink: (text, url, title) => _handleLinkTap(url),
          ),
          const SizedBox(height: 8),
        ],

        // MushroomDescription paragraphs
        for (final paragraph in retreat.mushroomDescription) ...[
          MarkdownBody(
            data: paragraph,
            styleSheet:
            MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                height: 1.4,
              ),
            ),
            onTapLink: (text, url, title) => _handleLinkTap(url),
          ),
          const SizedBox(height: 12),
        ],

        // Button to go to your mushroom order screen
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PsychedelicOrderScreen(
                  retreatId: retreat.id,
                  userId: widget.participant.userId,
                  isMushroomOrder: true,  // <--- Mushrooms
                ),
              ),
            );
          },
          child: const Text('Order Mushrooms'),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5) Truffle Section (show if showTruffleOrder == true)
  Widget _buildTrufflesSection(Retreat retreat) {
    // This uses hypothetical fields 'truffleTitle' and 'truffleDescription'
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (retreat.truffleTitle.isNotEmpty) ...[
          MarkdownBody(
            data: retreat.truffleTitle,
            styleSheet:
            MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
            onTapLink: (text, url, title) => _handleLinkTap(url),
          ),
          const SizedBox(height: 8),
        ],

        for (final paragraph in retreat.truffleDescription) ...[
          MarkdownBody(
            data: paragraph,
            styleSheet:
            MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                height: 1.4,
              ),
            ),
            onTapLink: (text, url, title) => _handleLinkTap(url),
          ),
          const SizedBox(height: 12),
        ],

        // Button to go to your truffle order screen
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PsychedelicOrderScreen(
                  retreatId: retreat.id,
                  userId: widget.participant.userId,
                  isMushroomOrder: false, // <--- Truffles
                ),
              ),
            );
          },
          child: const Text('Order Truffles'),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 6) Spotify
  Widget _buildSpotifySection(Retreat retreat) {
    final links = retreat.spotifyLinks;
    if (links.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Music',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Music plays a crucial role in our psychedelic retreats... (omitted for brevity)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        for (final link in links) ...[
          _buildSpotifyLinkTile(link),
          const SizedBox(height: 16),
        ],
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
          children: const [
            Icon(FontAwesomeIcons.spotify, color: Colors.white),
            SizedBox(width: 8),
            Text('Open Playlist', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7) Venue Section
  Widget _buildVenueSection(String? venueId) {
    if (venueId == null || venueId.isEmpty) {
      return const SizedBox.shrink();
    }

    final myRetreatService = Provider.of<MyRetreatService>(context, listen: false);

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
            const Text(
              'About the Venue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final paragraph in venue.detailedDescription) ...[
              MarkdownBody(
                data: paragraph,
                styleSheet:
                MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    height: 1.4,
                  ),
                  h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                separatorBuilder: (context, index) =>
                const SizedBox(width: 16),
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
                        child: Image.network(
                          imageUrl,
                          width: 150,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
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

  // ---------------------------------------------------------------------------
  // 8) Fellow Numinauts
  Widget _buildFellowNuminautsSection(Retreat retreat) {
    final retreatService = Provider.of<RetreatService>(context, listen: false);
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

        if (sharingParticipants.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'My Fellow Numinauts',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('No participants have chosen to share their bios yet.'),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Fellow Numinauts',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: sharingParticipants.length,
                separatorBuilder: (context, index) => const SizedBox(width: 20),
                itemBuilder: (context, index) {
                  final participant = sharingParticipants[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParticipantProfileScreen(
                            participant: participant,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Hero(
                          tag: participant.photoUrl ?? participant.userId,
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: participant.photoUrl != null
                                ? CachedNetworkImageProvider(
                                participant.photoUrl!)
                                : null,
                            child: participant.photoUrl == null
                                ? const Icon(Icons.person,
                                size: 40, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 80,
                          child: Text(
                            participant.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
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

  // ---------------------------------------------------------------------------
  // 9) MEQ & Feedback
  Widget _buildMEQAndFeedbackSection(Retreat retreat, Participant participant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mystical Experience Questionnaire (MEQ) & Feedback',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Here you can fill out the MEQ forms before and after your experience, and leave feedback.',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton(
              onPressed: retreat.showMEQ ? _onMEQButtonPressed : null,
              child: const Text('MEQ Forms'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: retreat.showFeedback ? () {} : null,
              child: const Text('Feedback'),
            ),
          ],
        ),
      ],
    );
  }

  // Handle MEQ Consent
  void _onMEQButtonPressed() async {
    final participant = widget.participant;
    if (participant.meqConsent || _meqConsentDialogAccepted) {
      // navigate to MEQ
      return;
    }

    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('MEQ Consent'),
        content: SingleChildScrollView(
          child: Column(
            children: const [
              Text(
                'Please read and accept the following consent form before proceeding to the MEQ.',
              ),
              SizedBox(height: 16),
              Text(
                '[Consent Form Text Goes Here...]',
                style: TextStyle(color: Colors.grey),
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
      setState(() {
        _meqConsentDialogAccepted = true;
      });
      // Update participant's meqConsent if needed
      // final retreatService = Provider.of<RetreatService>(context, listen: false);
      // retreatService.addOrUpdateParticipant(...);
      // Navigator.push(...);
    }
  }

  // Handle link taps in Markdown
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

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackbar("Cannot open link: $url");
    }
  }
}
