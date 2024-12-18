// services/day_detail_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/day_detail.dart';
import '../models/daymodule.dart';
import '../models/article.dart';

class DayDetailService {
  final FirebaseFirestore firestore;

  DayDetailService(this.firestore);

  Future<DayDetail> getDayDetail(int dayNumber) async {
    final doc = await firestore.collection('days').doc('$dayNumber').get();
    if (!doc.exists) {
      throw Exception("Day detail not found for day $dayNumber");
    }

    final data = doc.data()!;
    print("Raw data for day $dayNumber: $data");

    // **Remove the following block since 'dayNumber' is not in data**
    /*
    final fetchedDayNumber = data['dayNumber'];
    if (fetchedDayNumber == null) {
      throw Exception("dayNumber is null in day $dayNumber data");
    } else if (fetchedDayNumber is! int) {
      throw Exception("dayNumber is not an int in day $dayNumber data: $fetchedDayNumber");
    }
    */

    // Parse title
    final fetchedTitle = data['title'];
    if (fetchedTitle == null || fetchedTitle is! String) {
      throw Exception("title is missing or not a string in day $dayNumber data");
    }

    // Parse heroImagePath
    final fetchedHeroImagePath = data['heroImagePath'];
    if (fetchedHeroImagePath == null || fetchedHeroImagePath is! String) {
      throw Exception("heroImagePath is missing or not a string in day $dayNumber data");
    }

    // Parse tasks
    List<DayModule> tasks = [];
    if (data['tasks'] != null && data['tasks'] is List) {
      final taskList = List<Map<String, dynamic>>.from(data['tasks']);
      print("Parsing ${taskList.length} tasks");
      tasks = taskList.map((taskData) {
        try {
          return DayModule.fromMap(taskData);
        } catch (e) {
          print("Error parsing task: $taskData, error: $e");
          throw Exception("Error parsing task: $taskData, error: $e");
        }
      }).toList();
    } else {
      print("No tasks found for day $dayNumber");
    }

    // Parse meditationTitle
    final fetchedMeditationTitle = data['meditationTitle'];
    if (fetchedMeditationTitle != null && fetchedMeditationTitle is! String) {
      throw Exception("meditationTitle is not a string in day $dayNumber data");
    }

    // Parse meditationUrl
    final fetchedMeditationUrl = data['meditationUrl'];
    if (fetchedMeditationUrl != null && fetchedMeditationUrl is! String) {
      throw Exception("meditationUrl is not a string in day $dayNumber data");
    }

    // Parse articles
    List<Article> articles = [];
    if (data['articles'] != null && data['articles'] is List) {
      final articleList = List<Map<String, dynamic>>.from(data['articles']);
      print("Parsing ${articleList.length} articles");
      articles = articleList.map((articleData) {
        try {
          return Article.fromMap(articleData);
        } catch (e) {
          print("Error parsing article: $articleData, error: $e");
          throw Exception("Error parsing article: $articleData, error: $e");
        }
      }).toList();
    } else {
      print("No articles found for day $dayNumber");
    }

    return DayDetail(
      dayNumber: dayNumber, // Use the parameter directly
      title: fetchedTitle as String,
      heroImagePath: fetchedHeroImagePath as String,
      tasks: tasks,
      meditationTitle: fetchedMeditationTitle as String? ?? "",
      meditationUrl: fetchedMeditationUrl as String? ?? "",
      articles: articles,
    );
  }
}