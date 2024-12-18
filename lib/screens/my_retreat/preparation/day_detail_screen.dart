import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '/models/day_detail.dart';
import '/models/daymodule.dart';
import '/models/article.dart';
import '/services/day_detail_service.dart';

class DayDetailScreen extends StatefulWidget {
  final int dayNumber;
  final bool isDayCompleted; // New: indicates if this day was previously completed

  DayDetailScreen({required this.dayNumber, this.isDayCompleted = false});

  @override
  _DayDetailScreenState createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  final DayDetailService _service = DayDetailService(FirebaseFirestore.instance);
  DayDetail? _dayDetail;
  bool _isLoading = true;
  Map<String, bool> _taskCompletion = {};

  @override
  void initState() {
    super.initState();
    _fetchDayDetails();
  }

  void _fetchDayDetails() async {
    try {
      final details = await _service.getDayDetail(widget.dayNumber);
      setState(() {
        _dayDetail = details;
        _isLoading = false;
        // If day is already completed, mark all tasks as completed
        _taskCompletion = Map.fromIterable(
          details.tasks,
          key: (task) => (task as DayModule).title,
          value: (_) => widget.isDayCompleted ? true : false,
        );
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _areAllTasksCompleted() {
    return _taskCompletion.values.every((isCompleted) => isCompleted);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(0xFFB4347F);

    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_dayDetail == null) {
      return Scaffold(
        body: Center(
          child: Text("Error loading day details. Please try again."),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(accentColor),
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.grey[50],
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDayTitle(accentColor),
                      SizedBox(height: 8),
                      _buildDayDescription(),
                      SizedBox(height: 24),

                      // Tasks
                      _buildTasksHeader(),
                      SizedBox(height: 16),
                      _buildTasksList(),
                      SizedBox(height: 24),

                      // Meditation
                      if (_dayDetail!.meditationTitle.isNotEmpty) ...[
                        _buildSectionHeader("Meditation"),
                        SizedBox(height: 8),
                        _buildMeditationPlayer(),
                        SizedBox(height: 24),
                      ],

                      // Articles
                      if (_dayDetail!.articles.isNotEmpty) ...[
                        _buildSectionHeader("Articles & Resources"),
                        SizedBox(height: 8),
                        ..._dayDetail!.articles.map((article) => _buildArticleCard(article)).toList(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_areAllTasksCompleted() && !widget.isDayCompleted)
            Positioned(
              bottom: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: () {
                  // Mark the day as completed and return true
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                ),
                child: Text("Mark Day as Completed", style: TextStyle(fontSize: 16)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(Color accentColor) {
    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      backgroundColor: accentColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          "Day ${_dayDetail!.dayNumber}",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(offset: Offset(0, 1), blurRadius: 2.0, color: Colors.black54)],
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

  Widget _buildDayTitle(Color accentColor) {
    return Text(
      _dayDetail!.title,
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: accentColor),
    );
  }

  Widget _buildDayDescription() {
    return Text(
      "Follow today's tasks and take your time to reflect and grow.",
      style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
    );
  }

  Widget _buildTasksHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Today's Tasks",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        if (widget.isDayCompleted)
          Text(
            "Completed",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[700]),
          ),
      ],
    );
  }

  Widget _buildTasksList() {
    return AnimationLimiter(
      child: Column(
        children: List.generate(_dayDetail!.tasks.length, (index) {
          final task = _dayDetail!.tasks[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: Duration(milliseconds: 300),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildInteractiveTaskCard(task),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInteractiveTaskCard(DayModule task) {
    final isCompleted = _taskCompletion[task.title] ?? false;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Theme(
        data: ThemeData(
          checkboxTheme: CheckboxThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          ),
        ),
        child: CheckboxListTile(
          title: Text(
            task.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
              color: isCompleted ? Colors.grey[600] : Colors.black87,
            ),
          ),
          subtitle: Text(
            task.description,
            style: TextStyle(
              decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
              color: isCompleted ? Colors.grey[600] : Colors.black54,
            ),
          ),
          value: isCompleted,
          onChanged: widget.isDayCompleted
              ? null
              : (bool? value) {
            setState(() {
              _taskCompletion[task.title] = value ?? false;
            });
          },
          activeColor: Color(0xFFB4347F),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildMeditationPlayer() {
    final accentColor = Color(0xFFB4347F);
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.play_circle_fill, color: accentColor, size: 40),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              "Listen to: ${_dayDetail!.meditationTitle}",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(Article article) {
    final accentColor = Color(0xFFB4347F);
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(Icons.article, color: accentColor),
        title: Text(article.title, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(article.description),
        trailing: Icon(Icons.open_in_new, color: Colors.grey),
        onTap: () {
          _launchURL(article.url);
        },
      ),
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch the article URL.')),
      );
    }
  }
}
