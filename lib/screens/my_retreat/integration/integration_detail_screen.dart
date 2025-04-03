import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '/models/day_detail.dart';
import '/models/article.dart';
import '/screens/my_retreat/audio_player_screen.dart';
import '/viewmodels/integration_day_detail_provider.dart';

class IntegrationDayDetailScreen extends StatefulWidget {
  final int dayNumber;
  final bool isDayCompleted;

  const IntegrationDayDetailScreen({
    Key? key,
    required this.dayNumber,
    this.isDayCompleted = false,
  }) : super(key: key);

  @override
  _IntegrationDayDetailScreenState createState() => _IntegrationDayDetailScreenState();
}

class _IntegrationDayDetailScreenState extends State<IntegrationDayDetailScreen> {
  // Integration theme colors
  final Color _primaryColor = const Color(0xFF1B4332); // Deep forest green
  final Color _secondaryColor = const Color(0xFF2D6A4F); // Rich emerald
  final Color _backgroundColor = const Color(0xFFF0F7F4); // Soft mint background

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Updated to use IntegrationDayDetailProvider
      final provider = Provider.of<IntegrationDayDetailProvider>(context, listen: false);
      provider.fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Updated to use IntegrationDayDetailProvider
    final provider = context.watch<IntegrationDayDetailProvider>();
    final dayDetail = provider.dayDetail;

    if (provider.isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: _primaryColor)),
      );
    }

    if (dayDetail == null) {
      return Scaffold(
        body: Center(child: Text("Error loading integration details")),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(dayDetail),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDayTitle(dayDetail),
                      const SizedBox(height: 16),

                      // Mindfulness Exercise
                      if (dayDetail.meditationTitle.isNotEmpty) ...[
                        _buildSectionHeader("Today's Mindfulness Practice"),
                        const SizedBox(height: 8),
                        _buildMindfulnessPlayer(dayDetail),
                        const SizedBox(height: 24),
                      ],

                      // Integration Tasks
                      _buildSectionHeader("Integration Tasks"),
                      const SizedBox(height: 16),
                      _buildTasksList(provider, dayDetail),
                      const SizedBox(height: 24),

                      // Journal Prompts
                      _buildSectionHeader("Journal Prompts"),
                      const SizedBox(height: 8),
                      _buildJournalPrompts(dayDetail),
                      const SizedBox(height: 24),

                      // Integration Resources
                      if (dayDetail.articles.isNotEmpty) ...[
                        _buildSectionHeader("Integration Resources"),
                        const SizedBox(height: 8),
                        ...dayDetail.articles
                            .map((article) => _buildResourceCard(article))
                            .toList(),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (provider.areAllTasksCompleted() && !widget.isDayCompleted)
            _buildCompleteDayButton(provider),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(DayDetail dayDetail) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: _primaryColor, // Use the primary green color
      centerTitle: true, // Center the title
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true, // Center the title in the FlexibleSpaceBar too
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
          textAlign: TextAlign.center, // Ensure text is centered
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/myretreat/integration_daymodule.png',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _primaryColor.withOpacity(0.1), // More visible gradient
                    _secondaryColor.withOpacity(0.5), // More visible gradient
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTitle(DayDetail dayDetail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dayDetail.title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Take time to reflect and integrate your experiences through today's practices.",
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: _primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMindfulnessPlayer(DayDetail dayDetail) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
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
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.self_improvement, color: _primaryColor, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayDetail.meditationTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      "Today's mindfulness practice",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.play_circle_filled, color: _primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTasksList(IntegrationDayDetailProvider provider, DayDetail dayDetail) {
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
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Theme(
                    data: ThemeData(
                      checkboxTheme: CheckboxThemeData(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          decoration: provider.taskCompletion[task.title] == true
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        task.description,
                        style: TextStyle(
                          color: provider.taskCompletion[task.title] == true
                              ? Colors.grey
                              : Colors.black87,
                        ),
                      ),
                      value: provider.taskCompletion[task.title] ?? false,
                      onChanged: widget.isDayCompleted
                          ? null
                          : (value) =>
                          provider.toggleTaskCompletion(task.title, value ?? false),
                      activeColor: _primaryColor,
                      checkColor: Colors.white,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildJournalPrompts(DayDetail dayDetail) {
    final journalTasks = dayDetail.tasks
        .where((task) => task.title.toLowerCase().contains('journal'))
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, color: _primaryColor),
                const SizedBox(width: 8),
                const Text(
                  "Reflect on these prompts:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...journalTasks.map((task) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                "• ${task.description}",
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(Article article) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(Icons.menu_book, color: _primaryColor),
        title: Text(
          article.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              article.description,
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.3,
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.open_in_new, color: _primaryColor),
        onTap: () async {
          final uri = Uri.parse(article.url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }

  Widget _buildCompleteDayButton(IntegrationDayDetailProvider provider) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: ElevatedButton(
        onPressed: () => _markDayAsCompleted(provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
        ),
        child: const Text(
          "Complete Today's Integration",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Future<void> _markDayAsCompleted(IntegrationDayDetailProvider provider) async {
    await provider.markDayAsCompleted();
    Navigator.pop(context, true);
  }
}