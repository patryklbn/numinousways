// models/article.dart
class Article {
  final String title;
  final String url;
  final String description;

  Article({
    required this.title,
    required this.url,
    required this.description,
  });

  factory Article.fromMap(Map<String, dynamic> map) {
    return Article(
      title: map['title'] as String,
      url: map['url'] as String,
      description: map['description'] as String,
    );
  }

  // Convert the Article instance to a map.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'url': url,
    };
  }

}