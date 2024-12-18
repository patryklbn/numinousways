// models/daymodule.dart
class DayModule {
  final int dayNumber;
  final String title;
  final String description;
  final bool isLocked;
  final bool isCompleted;

  DayModule({
    required this.dayNumber,
    required this.title,
    required this.description,
    this.isLocked = true,
    this.isCompleted = false,
  });

  factory DayModule.fromMap(Map<String, dynamic> map) {
    return DayModule(
      dayNumber: map['dayNumber'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      isLocked: map['isLocked'] as bool? ?? true,
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }

  DayModule copyWith({
    int? dayNumber,
    String? title,
    String? description,
    bool? isLocked,
    bool? isCompleted,
  }) {
    return DayModule(
      dayNumber: dayNumber ?? this.dayNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      isLocked: isLocked ?? this.isLocked,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}