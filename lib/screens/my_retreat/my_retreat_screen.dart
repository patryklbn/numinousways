import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../screens/full_screen_image_viewer.dart';

class MyRetreatScreen extends StatelessWidget {
  const MyRetreatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final facilitators = [
      {
        'name': 'Dr Christoph Zwolan',
        'role': 'CLINICAL DIRECTOR | PSYCHOLOGIST',
        'photoUrl': 'assets/images/myretreat/facilitatots/zwolan.png',
      },
      {
        'name': 'Danielle Tanner',
        'role': 'BODY THERAPIST | CLINICAL SUPERVISOR',
        'photoUrl': 'assets/images/myretreat/facilitatots/danielle.png',
      },
      {
        'name': 'Roger Duncan',
        'role': 'SYSTEMIC PSYCHOTHERAPIST | RETREAT FACILITATOR',
        'photoUrl': 'assets/images/myretreat/facilitatots/duncan.png',
      },
      {
        'name': 'Dr Jake Hawthorn',
        'role': 'PSYCHIATRIST | RETREAT FACILITATOR',
        'photoUrl': 'assets/images/myretreat/facilitatots/hawthorn.png',
      },
      {
        'name': 'Shashank Mishra',
        'role': 'COUNSELLOR | RETREAT FACILITATOR',
        'photoUrl': 'assets/images/myretreat/facilitatots/mishra.png',
      },
      {
        'name': 'Sam Bloomfield',
        'role': 'ARTS PSYCHOTHERAPIST | RETREAT FACILITATOR',
        'photoUrl': 'assets/images/myretreat/facilitatots/bloomfield.png',
      },
      {
        'name': 'Michal Topolski',
        'role': 'RETREAT FACILITATOR',
        'photoUrl': 'assets/images/myretreat/facilitatots/topolski.png',
      },
      {
        'name': 'John Siddique',
        'role': 'MEDITATION TEACHER',
        'photoUrl': 'assets/images/myretreat/facilitatots/siddique.png',
      },
      {
        'name': 'Ana Jorge',
        'role': 'RETREAT ASSISTANT',
        'photoUrl': 'assets/images/myretreat/facilitatots/jorge.png',
      },
    ];

    final portugalImages = [
      'assets/images/myretreat/portgual/portugal1.png',
      'assets/images/myretreat/portgual/portugal2.png',
      'assets/images/myretreat/portgual/portugal3.png',
      'assets/images/myretreat/portgual/portugal4.png',
      'assets/images/myretreat/portgual/portugal5.png',
      'assets/images/myretreat/portgual/portugal6.png',
    ];

    final netherlandsImages = [
      'assets/images/myretreat/netherland/netherland1.png',
      'assets/images/myretreat/netherland/netherland2.png',
      'assets/images/myretreat/netherland/netherland3.png',
      'assets/images/myretreat/netherland/netherland4.png',
      'assets/images/myretreat/netherland/netherland5.png',
      'assets/images/myretreat/netherland/netherland6.png',
    ];

    return Scaffold(
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
                        portugalImages,
                        context,
                        'Our venues in Portugal offer spacious rooms, open spaces for meditation and breathwork as well as an array of facilities including a heated pool and sauna.',
                      ),
                      SizedBox(height: 32),
                      _buildVenuesSection(
                        'Netherlands',
                        netherlandsImages,
                        context,
                        'Our Netherlands location is a sanctuary amidst luscious green spaces where nature’s embrace invites tranquillity and rejuvenation. A perfect setting for introspection and deep journeying during your psychedelic retreat.',
                      ),
                      SizedBox(height: 32),
                      _buildFacilitatorsSection(facilitators),
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
        fontSize: 14, // Adjusted as per your latest code
        fontWeight: FontWeight.w600,
        fontFamily: 'Roboto', // Added Roboto font
        color: Colors.black87,
        height: 1.6, // Line height for readability
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

    // Updated descriptions
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
    // Determine background image based on title
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

    // Adjust font sizes
    double titleFontSize = isLarge ? 20 : 18;
    double descriptionFontSize = isLarge ? 18 : 16;
    double iconSize = isLarge ? 50 : 40;

    // Slightly darker overlay for better contrast
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
              color: Colors.white, // Changed icon color to white
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

  Widget _buildVenuesSection(String title, List<String> images, BuildContext context, String description) {
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
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (context, index) => SizedBox(width: 16),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImageViewer(
                        imagePath: images[index],
                        tag: '$title-$index',
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: '$title-$index',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      images[index],
                      width: 150,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildFacilitatorsSection(List<Map<String, String>> facilitators) {
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
        SizedBox(
          height: 140, // Increased height to accommodate name and role
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: facilitators.length,
            separatorBuilder: (context, index) => SizedBox(width: 16),
            itemBuilder: (context, index) {
              final facilitator = facilitators[index];
              return GestureDetector(
                onTap: () {
                  // Navigate to facilitator detail screen if exists
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage(facilitator['photoUrl']!),
                    ),
                    SizedBox(height: 8),
                    Text(
                      facilitator['name']!,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      facilitator['role']!,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]), // Adjusted font size to 11
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
