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
    this.dueDate,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  String title;
  bool isCompleted;
  final DateTime createdAt;
  final List<Subtask> subtasks;

  /// Optional due-date the user can assign.
  /// Stored as an ISO-8601 date string (UTC midnight) or null.
  final DateTime? dueDate;

  Todo copyWith({
    String? title,
    bool? isCompleted,
    List<Subtask>? subtasks,
    DateTime? dueDate,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      subtasks: subtasks ?? this.subtasks,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  /// Whether the due date has passed (ignores time, compares calendar dates).
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final today = DateTime(now.year, now.month, now.day);
    return due.isBefore(today);
  }

  /// Whether the due date is today.
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
    'subtasks': subtasks.map((s) => s.toJson()).toList(),
    if (dueDate != null)
      'dueDate': DateTime(
        dueDate!.year,
        dueDate!.month,
        dueDate!.day,
      ).toIso8601String(),
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
    dueDate: json['dueDate'] != null
        ? DateTime.parse(json['dueDate'] as String)
        : null,
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
