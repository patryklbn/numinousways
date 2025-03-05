import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/facilitator.dart';
import '../../models/venue.dart';
import '../../services/myretreat_service.dart';
import '../../services/login_provider.dart';
import '../login/login_screen.dart';
import '/widgets/app_drawer.dart';
import 'facilitator_profile_screen.dart';

class GalleryViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String title;

  const GalleryViewer({
    Key? key,
    required this.images,
    required this.initialIndex,
    required this.title,
  }) : super(key: key);

  @override
  State<GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<GalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        centerTitle: true,
        title: Text(
          '${widget.title} (${_currentIndex + 1}/${widget.images.length})',
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return Hero(
            tag: '${widget.title}-$index',
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: widget.images[index],
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.error,
                  color: Colors.white,
                ),
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}

class MyRetreatScreen extends StatelessWidget {
  const MyRetreatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);

    if (!loginProvider.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentUserId = loginProvider.userId!;
    final myRetreatService = Provider.of<MyRetreatService>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const AppDrawer(),
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
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      _buildIntroText(context),
                      const SizedBox(height: 24),
                      _buildFeatureCards(context),
                      const SizedBox(height: 32),
                      _buildVenuesSection(
                        'Portugal',
                        context,
                        'Our venues in Portugal offer spacious rooms, open spaces for meditation and breathwork as well as an array of facilities including a heated pool and sauna.',
                        myRetreatService,
                        currentUserId,
                      ),
                      const SizedBox(height: 32),
                      _buildVenuesSection(
                        'Netherlands',
                        context,
                        'Our Netherlands location is a sanctuary amidst luscious green spaces where nature embrace invites tranquillity and rejuvenation.',
                        myRetreatService,
                        currentUserId,
                      ),
                      const SizedBox(height: 32),
                      _buildFacilitatorsSection(context, myRetreatService, currentUserId),
                      const SizedBox(height: 32),
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
      elevation: 0,
      centerTitle: true, // Ensures the title is centered on Android as well
      backgroundColor: const Color(0xFFB4347F),
      flexibleSpace: FlexibleSpaceBar(
        // This ensures the text is centered consistently across platforms
        centerTitle: true,
        // You can adjust titlePadding if you want precise centering when collapsed:
        // titlePadding: const EdgeInsets.only(bottom: 16.0),
        title: const Text(
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
          textAlign: TextAlign.center,
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'retreat-hero',
              child: Image.asset(
                'assets/images/myretreat/myretreathero.png',
                fit: BoxFit.cover,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroText(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Text(
        'At Numinous Ways, our retreats seamlessly guide you through essential preparation, immersive experiences, and mindful integration. With curated tasks, transformative exercises, and supportive environments, we create a nurturing space for profound personal growth and self-discovery.',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
          color: Colors.black87,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildFeatureCards(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double horizontalPadding = 16 * 2;
    double availableWidth = screenWidth - horizontalPadding;

    const prepDescription = '21-day checklist & tasks';
    const expDescription = 'Schedule & feedback';
    const intDescription = 'Mindfulness tools';

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
              const SizedBox(width: 16),
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
        const SizedBox(height: 16),
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
    } else {
      backgroundImage = 'assets/images/myretreat/integration.png';
    }

    return Hero(
      tag: 'feature-$title',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, routeName),
          borderRadius: BorderRadius.circular(isLarge ? 16 : 12),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isLarge ? 16 : 12),
              image: DecorationImage(
                image: AssetImage(backgroundImage),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.3),
                  BlendMode.darken,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: isLarge ? 50 : 40,
                  color: Colors.white,
                ),
                SizedBox(height: isLarge ? 16 : 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isLarge ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isLarge ? 18 : 16,
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.w500,
                    shadows: const [
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
        ),
      ),
    );
  }

  Widget _buildVenuesSection(
      String title,
      BuildContext context,
      String description,
      MyRetreatService service,
      String currentUserId,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<Venue>>(
          stream: service.getVenues(currentUserId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Error fetching venues');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final venues = snapshot.data!;
            final filteredVenues = venues
                .where((venue) => venue.name.toLowerCase() == title.toLowerCase())
                .toList();

            if (filteredVenues.isEmpty) {
              return Text('No $title venues available');
            }

            final venue = filteredVenues.first;
            final images = venue.images;

            return SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final imageUrl = images[index];
                  return Hero(
                    tag: '$title-$index',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) =>
                                  GalleryViewer(
                                    images: images,
                                    initialIndex: index,
                                    title: title,
                                  ),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            placeholder: (context, url) => Container(
                              width: 150,
                              height: 120,
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 150,
                              height: 120,
                              color: Colors.grey[300],
                              child: const Icon(Icons.error),
                            ),
                            width: 150,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
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

  Widget _buildFacilitatorsSection(
      BuildContext context,
      MyRetreatService service,
      String currentUserId,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meet Our Team',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Expert facilitators here to support you.',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<Facilitator>>(
          stream: service.getFacilitators(currentUserId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Error fetching facilitators');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final facilitators = snapshot.data!;

            return SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: facilitators.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final facilitator = facilitators[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 400),
                    child: SlideAnimation(
                      horizontalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                      FacilitatorProfileScreen(facilitator: facilitator),
                                  transitionsBuilder:
                                      (context, animation, secondaryAnimation, child) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Hero(
                                  tag: 'facilitator-${facilitator.id}',
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
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  facilitator.role,
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
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
        ),
      ],
    );
  }
}
