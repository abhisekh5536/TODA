import 'dart:convert';

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
  };

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
    id: json['id'] as String,
    title: json['title'] as String,
    isCompleted: json['isCompleted'] as bool? ?? false,
  );
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
    'subtasks': subtasks.map((s) => s.toJson()).toList(),
  };

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
    id: json['id'] as String,
    title: json['title'] as String,
    isCompleted: json['isCompleted'] as bool? ?? false,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
    subtasks: (json['subtasks'] as List<dynamic>?)
            ?.map((s) => Subtask.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

/// Helper to encode/decode the full todo list for storage.
String encodeTodos(List<Todo> todos) {
  return jsonEncode(todos.map((t) => t.toJson()).toList());
}

List<Todo> decodeTodos(String data) {
  if (data.isEmpty) return [];
  final list = jsonDecode(data) as List<dynamic>;
  return list.map((t) => Todo.fromJson(t as Map<String, dynamic>)).toList();
}
