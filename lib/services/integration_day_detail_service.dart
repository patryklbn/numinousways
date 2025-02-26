import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/day_detail.dart';
import '/models/daymodule.dart';
import '/models/article.dart';

class IntegrationDayDetailService {
  final FirebaseFirestore firestore;

  IntegrationDayDetailService(this.firestore);

  Future<DayDetail> getDayDetail(int dayNumber) async {
    try {
      // Note the different collection name here
      final doc = await firestore.collection('integration_days').doc('$dayNumber').get();

      if (!doc.exists) {
        throw Exception("Integration day detail not found for day $dayNumber");
      }

      final data = doc.data()!;
      final fetchedTitle = data['title'] as String;
      final fetchedHeroImagePath = data['heroImagePath'] as String? ??
          'assets/images/myretreat/integration_daymodule.png'; // Default integration image

      // Parse tasks
      final List tasksData = data['tasks'] ?? [];
      final tasks = tasksData.map((td) => DayModule.fromMap(td)).toList();

      // Parse meditation data
      final fetchedMeditationTitle = data['meditationTitle'] as String? ?? "";
      final fetchedMeditationUrl = data['meditationUrl'] as String? ?? "";

      // Parse articles
      final List articlesData = data['articles'] ?? [];
      final articles = articlesData.map((ad) => Article.fromMap(ad)).toList();

      return DayDetail(
        dayNumber: dayNumber,
        title: fetchedTitle,
        heroImagePath: fetchedHeroImagePath,
        tasks: tasks,
        meditationTitle: fetchedMeditationTitle,
        meditationUrl: fetchedMeditationUrl,
        articles: articles,
      );
    } catch (e) {
      print('Error getting integration day detail: $e');
      rethrow;
    }
  }
}