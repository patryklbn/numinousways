import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../models/experience/retreat.dart';
import '../../../models/experience/participant.dart';
import '../../../widgets/experience/small_map_widget.dart';

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

  @override
  Widget build(BuildContext context) {
    final retreat = widget.retreat;
    final participant = widget.participant;

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

            // 2) Detailed description (as Markdown)
            _buildDetailedDescriptionMarkdown(retreat),

            const SizedBox(height: 24),

            // 3) Buttons: Submit Travel Details + Complete About Me
            _buildMainActionButtons(),

            const SizedBox(height: 24),

            // 4) About Your Travels
            _buildTravelSection(retreat),

            const SizedBox(height: 24),

            // 5) Order Mushrooms/Truffles button(s)
            _buildOrderButtons(retreat),

            const SizedBox(height: 24),

            // 6) Spotify playlist
            _buildSpotifySection(retreat),

            const SizedBox(height: 24),

            // 7) Fellow Numinauts (conditional)
            if (retreat.showFellowNuminauts)
              _buildFellowNuminautsSection(retreat),

            const SizedBox(height: 24),

            // 8) MEQ and Feedback
            _buildMEQAndFeedbackSection(retreat, participant),
          ],
        ),
      ),
    );
  }

  /// 1) Renders `detailedDescription` as Markdown
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
            onTapLink: (text, url, title) async {
              // Use our helper method
              await _handleLinkTap(url);
            },
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  /// 2) Main action buttons
  Widget _buildMainActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: () {
            // Navigator.push(...);
          },
          child: const Text('Submit Travel Details'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            // Navigator.push(...);
          },
          child: const Text('Complete About Me'),
        ),
      ],
    );
  }

  /// 3) "About your travels": heading, travelDescription (markdown), retreatAddress (markdown),
  /// map, then meeting/return lines below the map.
  Widget _buildTravelSection(Retreat retreat) {
    final hasTravel = retreat.travelDescription.isNotEmpty ||
        retreat.retreatAddress.isNotEmpty ||
        retreat.meetingLocation.isNotEmpty ||
        retreat.returnLocation.isNotEmpty ||
        (retreat.latitude != null && retreat.longitude != null);

    if (!hasTravel) {
      return const SizedBox.shrink(); // no travel info
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heading: About your travels
        Text(
          'About your travels',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // A) travelDescription as Markdown
        for (final mdText in retreat.travelDescription) ...[
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
            onTapLink: (text, url, title) async {
              await _handleLinkTap(url);
            },
          ),
          const SizedBox(height: 12),
        ],

        // B) Retreat address lines as Markdown (no heading)
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
              onTapLink: (text, url, title) async {
                await _handleLinkTap(url);
              },
            ),
            const SizedBox(height: 12),
          ],
        ],

        // C) Map below address
        if (retreat.latitude != null && retreat.longitude != null) ...[
          const SizedBox(height: 8),
          SmallMapWidget(
            latitude: retreat.latitude!,
            longitude: retreat.longitude!,
            zoomLevel: 11,
          ),
          const SizedBox(height: 16),
        ],

        // D) Meeting Location
        if (retreat.meetingLocation.isNotEmpty) ...[
          const Text(
            'Meeting Location:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          for (final line in retreat.meetingLocation) Text(line),
          const SizedBox(height: 12),
        ],

        // E) Return Location
        if (retreat.returnLocation.isNotEmpty) ...[
          const Text(
            'Return Location:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          for (final line in retreat.returnLocation) Text(line),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  /// 4) Mushrooms / Truffles
  Widget _buildOrderButtons(Retreat retreat) {
    final canOrderMushrooms = retreat.showMushroomOrder;
    final canOrderTruffles = retreat.showTruffleOrder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: canOrderMushrooms ? () {} : null,
          child: const Text('Order Mushrooms'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: canOrderTruffles ? () {} : null,
          child: const Text('Order Truffles'),
        ),
      ],
    );
  }

  /// 5) Spotify link
  Widget _buildSpotifySection(Retreat retreat) {
    final spotifyUrl = ''; // replace with retreat.spotifyUrl
    if (spotifyUrl.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Music / Spotify Playlist',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _launchUrl(spotifyUrl),
          child: Text(
            spotifyUrl,
            style: const TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  /// 6) Fellow Numinauts
  Widget _buildFellowNuminautsSection(Retreat retreat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Fellow Numinauts',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('No participants have chosen to share their bios yet.'),
      ],
    );
  }

  /// 7) MEQ + Feedback
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

  /// Show MEQ consent dialog if needed
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
              Text('Please read and accept the following consent form before proceeding to the MEQ.'),
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
      // participant.meqConsent = true;
      // await retreatService.addOrUpdateParticipant(...);
      // Navigator.push(...);
    }
  }

  /// Helper method: handle Markdown link taps
  Future<void> _handleLinkTap(String? url) async {
    if (url == null) return;

    if (url.startsWith('tel:')) {
      final Uri phoneUri = Uri.parse(url);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showSnackbar("Could not launch phone call");
      }
    } else {
      final Uri linkUri = Uri.parse(url);
      if (await canLaunchUrl(linkUri)) {
        await launchUrl(linkUri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackbar("Could not open link: $url");
      }
    }
  }

  /// Helper: show SnackBar
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Launch link in external browser/phone
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackbar("Cannot open link: $url");
    }
  }
}
