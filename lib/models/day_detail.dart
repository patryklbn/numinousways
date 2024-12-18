// models/day_detail.dart
import 'daymodule.dart';
import 'article.dart';

class DayDetail {
  final int dayNumber;
  final String title;
  final String heroImagePath;
  final List<DayModule> tasks;
  final String meditationTitle;
  final String meditationUrl;
  final List<Article> articles;

  DayDetail({
    required this.dayNumber,
    required this.title,
    required this.heroImagePath,
    required this.tasks,
    this.meditationTitle = "",
    this.meditationUrl = "",
    this.articles = const [],
  });
}