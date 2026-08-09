class Subtask {
  Subtask({required this.id, required this.title, this.isCompleted = false});

  final String id;
  String title;
  bool isCompleted;

  Subtask copyWith({String? title, bool? isCompleted}) {
    return Subtask(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class Todo {
  Todo({
    required this.id,
    required this.title,
    this.isCompleted = false,
    DateTime? createdAt,
    this.subtasks = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  String title;
  bool isCompleted;
  final DateTime createdAt;
  final List<Subtask> subtasks;

  Todo copyWith({String? title, bool? isCompleted, List<Subtask>? subtasks}) {
    return Todo(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      subtasks: subtasks ?? this.subtasks,
    );
  }
}
