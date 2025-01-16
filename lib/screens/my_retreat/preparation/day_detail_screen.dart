import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '/models/day_detail.dart';
import '/models/daymodule.dart';
import '/models/article.dart';
import '/screens/my_retreat/audio_player_screen.dart';
import 'package:numinous_way/viewmodels/day_detail_provider.dart';
// ^ or wherever you placed the new provider

class DayDetailScreen extends StatefulWidget {
  final int dayNumber;
  final bool isDayCompleted;

  const DayDetailScreen({
    Key? key,
    required this.dayNumber,
    this.isDayCompleted = false,
  }) : super(key: key);

  @override
  _DayDetailScreenState createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  final Color accentColor = const Color(0xFFB4347F);

  @override
  void initState() {
    super.initState();
    // After the widget is mounted, call fetchData on the provider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DayDetailProvider>(context, listen: false);
      provider.fetchData();
    });
  }

  bool _areAllTasksCompleted(DayDetailProvider provider) {
    return provider.areAllTasksCompleted() && !widget.isDayCompleted;
  }

  Future<void> _markDayAsCompleted(DayDetailProvider provider) async {
    await provider.markDayAsCompleted();
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    // Watch the dayDetail provider
    final provider = context.watch<DayDetailProvider>();
    final dayDetail = provider.dayDetail;

    if (provider.isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (dayDetail == null) {
      return Scaffold(
        body: Center(child: Text("Error loading day details. Please try again.")),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(dayDetail),
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.grey[50],
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDayTitle(dayDetail),
                      const SizedBox(height: 8),
                      _buildDayDescription(),
                      const SizedBox(height: 24),

                      // Tasks
                      _buildTasksHeader(),
                      const SizedBox(height: 16),
                      _buildTasksList(provider, dayDetail),
                      const SizedBox(height: 24),

                      // Meditation
                      if (dayDetail.meditationTitle.isNotEmpty) ...[
                        _buildSectionHeader("Meditation"),
                        const SizedBox(height: 8),
                        _buildMeditationPlayer(dayDetail),
                        const SizedBox(height: 24),
                      ],

                      // Articles
                      if (dayDetail.articles.isNotEmpty) ...[
                        _buildSectionHeader("Articles & Resources"),
                        const SizedBox(height: 8),
                        ...dayDetail.articles
                            .map((article) => _buildArticleCard(article))
                            .toList(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_areAllTasksCompleted(provider))
            Positioned(
              bottom: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: () => _markDayAsCompleted(provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  "Mark Day as Completed",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // SliverAppBar
  Widget _buildSliverAppBar(DayDetail dayDetail) {
    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      backgroundColor: accentColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          "Day ${dayDetail.dayNumber}",
          style: const TextStyle(
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
              'assets/images/myretreat/day_detail_hero.png',
              fit: BoxFit.cover,
            ),
            Container(color: Colors.black.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  // Day Title
  Widget _buildDayTitle(DayDetail dayDetail) {
    return Text(
      dayDetail.title,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: accentColor,
      ),
    );
  }

  // Day Description
  Widget _buildDayDescription() {
    return const Text(
      "Follow today's tasks and take your time to reflect and grow.",
      style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
    );
  }

  // Tasks header
  Widget _buildTasksHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Today's Tasks",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (widget.isDayCompleted)
          Text(
            "Completed",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
      ],
    );
  }

  // Tasks list
  Widget _buildTasksList(DayDetailProvider provider, DayDetail dayDetail) {
    return AnimationLimiter(
      child: Column(
        children: List.generate(dayDetail.tasks.length, (index) {
          final task = dayDetail.tasks[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 300),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildInteractiveTaskCard(provider, task),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Single Task Card
  Widget _buildInteractiveTaskCard(DayDetailProvider provider, DayModule task) {
    final isCompleted = provider.taskCompletion[task.title] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Theme(
        data: ThemeData(
          checkboxTheme: CheckboxThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        child: CheckboxListTile(
          title: Text(
            task.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted ? Colors.grey[600] : Colors.black87,
            ),
          ),
          subtitle: Text(
            task.description,
            style: TextStyle(
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted ? Colors.grey[600] : Colors.black54,
            ),
          ),
          value: isCompleted,
          onChanged: widget.isDayCompleted
              ? null // cannot change if day is completed
              : (bool? value) {
            provider.toggleTaskCompletion(task.title, value ?? false);
          },
          activeColor: accentColor,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
    );
  }

  // Section header
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  // Meditation Player
  Widget _buildMeditationPlayer(DayDetail dayDetail) {
    return InkWell(
      onTap: () {
        // Navigate to a dedicated audio player screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AudioPlayerScreen(
              audioUrl: dayDetail.meditationUrl,
              title: dayDetail.meditationTitle,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.play_circle_fill, color: accentColor, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                "Listen to: ${dayDetail.meditationTitle}",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: accentColor),
          ],
        ),
      ),
    );
  }

  // Articles
  Widget _buildArticleCard(Article article) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(Icons.article, color: accentColor),
        title: Text(article.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(article.description),
        trailing: const Icon(Icons.open_in_new, color: Colors.grey),
        onTap: () async {
          final uri = Uri.parse(article.url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not launch the article URL.')),
            );
          }
        },
      ),
    );
  }
}
