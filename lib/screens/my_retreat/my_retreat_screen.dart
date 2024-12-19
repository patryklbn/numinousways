import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/facilitator.dart';
import '../../models/venue.dart';
import '../../services/myretreat_service.dart';
import '../../services/login_provider.dart';
import '../../screens/full_screen_image_viewer.dart';
import '../login/login_screen.dart';
import '/widgets/app_drawer.dart'; 
import 'facilitator_profile_screen.dart';

class MyRetreatScreen extends StatelessWidget {
  const MyRetreatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);

    if (!loginProvider.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      });
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentUserId = loginProvider.userId!;
    final myRetreatService = Provider.of<MyRetreatService>(context, listen: false);

    return Scaffold(
      drawer: const AppDrawer(), // Add the drawer
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: AnimationLimiter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 500),
                    childAnimationBuilder: (widget) => FadeInAnimation(child: widget),
                    children: [
                      _buildIntroText(context),
                      SizedBox(height: 24),
                      _buildFeatureCards(context),
                      SizedBox(height: 32),
                      _buildVenuesSection(
                        'Portugal',
                        context,
                        'Our venues in Portugal offer spacious rooms, open spaces for meditation and breathwork as well as an array of facilities including a heated pool and sauna.',
                        myRetreatService,
                        currentUserId,
                      ),
                      SizedBox(height: 32),
                      _buildVenuesSection(
                        'Netherlands',
                        context,
                        'Our Netherlands location is a sanctuary amidst luscious green spaces where nature’s embrace invites tranquillity and rejuvenation.',
                        myRetreatService,
                        currentUserId,
                      ),
                      SizedBox(height: 32),
                      _buildFacilitatorsSection(context, myRetreatService, currentUserId),
                      SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      backgroundColor: Color(0xFFB4347F),
      // automaticallyImplyLeading defaults to true, so it will show the hamburger menu icon since we have a drawer
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'My Retreat',
          style: TextStyle(
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
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/myretreat/myretreathero.png',
              fit: BoxFit.cover,
            ),
            Container(color: Colors.black.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroText(BuildContext context) {
    return Text(
      'At Numinous Way, our retreats seamlessly guide you through essential preparation, immersive experiences, and mindful integration. With curated tasks, transformative exercises, and supportive environments, we create a nurturing space for profound personal growth and self-discovery.',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: 'Roboto',
        color: Colors.black87,
        height: 1.6,
        shadows: [
          Shadow(
            offset: Offset(0, 1),
            blurRadius: 2.0,
            color: Colors.black12,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCards(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double horizontalPadding = 16 * 2;
    double availableWidth = screenWidth - horizontalPadding;

    String prepDescription = '21-day checklist & tasks';
    String expDescription = 'Schedule & feedback';
    String intDescription = 'Mindfulness tools';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  context: context,
                  icon: Icons.check_circle_outline,
                  title: 'Preparation',
                  description: prepDescription,
                  routeName: '/preparation',
                  width: double.infinity,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildFeatureCard(
                  context: context,
                  icon: Icons.calendar_today_outlined,
                  title: 'Experience',
                  description: expDescription,
                  routeName: '/experience',
                  width: double.infinity,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        _buildFeatureCard(
          context: context,
          icon: Icons.self_improvement,
          title: 'Integration',
          description: intDescription,
          routeName: '/integration',
          width: availableWidth,
          isLarge: true,
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required String routeName,
    required double width,
    bool isLarge = false,
  }) {
    String backgroundImage;
    if (title == 'Preparation') {
      backgroundImage = 'assets/images/myretreat/preparation.png';
    } else if (title == 'Experience') {
      backgroundImage = 'assets/images/myretreat/experience.png';
    } else if (title == 'Integration') {
      backgroundImage = 'assets/images/myretreat/integration.png';
    } else {
      backgroundImage = '';
    }

    double titleFontSize = isLarge ? 20 : 18;
    double descriptionFontSize = isLarge ? 18 : 16;
    double iconSize = isLarge ? 50 : 40;
    double overlayOpacity = 0.3;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, routeName),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isLarge ? 16 : 12),
          boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black12)],
          image: backgroundImage.isNotEmpty
              ? DecorationImage(
            image: AssetImage(backgroundImage),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(overlayOpacity),
              BlendMode.darken,
            ),
          )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: Colors.white,
            ),
            SizedBox(height: isLarge ? 16 : 12),
            Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.black54,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: descriptionFontSize,
                color: Colors.white.withOpacity(0.95),
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.black54,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVenuesSection(String title, BuildContext context, String description, MyRetreatService service, String currentUserId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        SizedBox(height: 16),
        StreamBuilder<List<Venue>>(
          stream: service.getVenues(currentUserId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error fetching venues');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }

            final venues = snapshot.data!;
            final filteredVenues = venues.where((venue) => venue.name.toLowerCase() == title.toLowerCase()).toList();

            if (filteredVenues.isEmpty) {
              return Text('No $title venues available');
            }

            final venue = filteredVenues.first;

            return SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: venue.images.length,
                separatorBuilder: (context, index) => SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final imageUrl = venue.images[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImageViewer(
                            imageUrl: imageUrl,
                            tag: '$title-$index',
                          ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: '$title-$index',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          placeholder: (context, url) => Container(
                            width: 150,
                            height: 120,
                            color: Colors.grey[300],
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 150,
                            height: 120,
                            color: Colors.grey[300],
                            child: Icon(Icons.error),
                          ),
                          width: 150,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFacilitatorsSection(BuildContext context, MyRetreatService service, String currentUserId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meet Our Team',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Expert facilitators here to support you.',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        SizedBox(height: 16),
        StreamBuilder<List<Facilitator>>(
          stream: service.getFacilitators(currentUserId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error fetching facilitators');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }

            final facilitators = snapshot.data!;

            return SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: facilitators.length,
                separatorBuilder: (context, index) => SizedBox(width: 16),
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
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: CachedNetworkImageProvider(facilitator.photoUrl),
                        ),
                        SizedBox(height: 8),
                        Text(
                          facilitator.name,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4),
                        Text(
                          facilitator.role,
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
        ),
      ],
    );
  }
}
