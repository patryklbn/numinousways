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
    final fetchedTitle = data['title'] as String;
    final fetchedHeroImagePath = data['heroImagePath'] as String;
    final List tasksData = data['tasks'] ?? [];
    final tasks = tasksData.map((td) => DayModule.fromMap(td)).toList();

    final fetchedMeditationTitle = data['meditationTitle'] as String? ?? "";
    final fetchedMeditationUrl = data['meditationUrl'] as String? ?? "";
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
  }
}
