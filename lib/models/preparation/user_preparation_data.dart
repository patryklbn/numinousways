import 'package:cloud_firestore/cloud_firestore.dart';

class UserPreparationData {
  final DateTime? startDate;
  final List<UserModuleData> modules;

  UserPreparationData({
    this.startDate,
    this.modules = const [],
  });

  factory UserPreparationData.fromMap(Map<String, dynamic> map) {
    // Parse the startDate (if it exists)
    DateTime? start;
    if (map['startDate'] != null) {
      final timestamp = map['startDate'];
      // Firestore timestamps might come as Timestamp objects
      if (timestamp is DateTime) {
        start = timestamp;
      } else if (timestamp is Timestamp) {
        start = timestamp.toDate();
      }
    }

    List<UserModuleData> mods = [];
    if (map['modules'] is List) {
      final modulesList = List<Map<String, dynamic>>.from(map['modules']);
      mods = modulesList.map((m) => UserModuleData.fromMap(m)).toList();
    }

    return UserPreparationData(
      startDate: start,
      modules: mods,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startDate': startDate,
      'modules': modules.map((m) => m.toMap()).toList(),
    };
  }
}

class UserModuleData {
  final int dayNumber;
  final bool isLocked;
  final bool isCompleted;
  final Map<String, bool> tasks; // Key: task title, Value: completion state

  UserModuleData({
    required this.dayNumber,
    this.isLocked = true,
    this.isCompleted = false,
    this.tasks = const {},
  });

  factory UserModuleData.fromMap(Map<String, dynamic> map) {
    final tasksMap = <String, bool>{};
    if (map['tasks'] is Map) {
      (map['tasks'] as Map).forEach((key, value) {
        tasksMap[key] = value == true;
      });
    }

    return UserModuleData(
      dayNumber: map['dayNumber'] as int,
      isLocked: map['isLocked'] as bool? ?? true,
      isCompleted: map['isCompleted'] as bool? ?? false,
      tasks: tasksMap,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayNumber': dayNumber,
      'isLocked': isLocked,
      'isCompleted': isCompleted,
      'tasks': tasks,
    };
  }

  UserModuleData copyWith({
    int? dayNumber,
    bool? isLocked,
    bool? isCompleted,
    Map<String, bool>? tasks,
  }) {
    return UserModuleData(
      dayNumber: dayNumber ?? this.dayNumber,
      isLocked: isLocked ?? this.isLocked,
      isCompleted: isCompleted ?? this.isCompleted,
      tasks: tasks ?? this.tasks,
    );
  }
}
