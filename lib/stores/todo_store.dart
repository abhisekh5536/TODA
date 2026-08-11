import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/todo.dart';

enum Filter { all, active, completed }

class TodoStore extends ChangeNotifier {
  final List<Todo> _todos = [];
  int _idSeq = 0;
  bool _loaded = false;

  static const _storageKey = 'todo_app_todos';

  String _newId() => '${DateTime.now().microsecondsSinceEpoch}-${_idSeq++}';

  List<Todo> get todos => List.unmodifiable(_todos);

  Todo? byId(String id) {
    for (final todo in _todos) {
      if (todo.id == id) return todo;
    }
    return null;
  }

  int _indexOf(String id) =>
      _todos.indexWhere((t) => t.id == id);

  List<Todo> filtered(Filter filter) {
    switch (filter) {
      case Filter.all:
        return _todos;
      case Filter.active:
        return _todos.where((t) => !t.isCompleted).toList();
      case Filter.completed:
        return _todos.where((t) => t.isCompleted).toList();
    }
  }

  /// Return todos whose dueDate falls on the given calendar day.
  List<Todo> todosForDate(DateTime day) {
    return _todos.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == day.year &&
          t.dueDate!.month == day.month &&
          t.dueDate!.day == day.day;
    }).toList();
  }

  /// Return a map of date → task count for the given month (for calendar markers).
  Map<DateTime, int> taskCountsForMonth(DateTime month) {
    final map = <DateTime, int>{};
    for (final todo in _todos) {
      if (todo.dueDate == null) continue;
      final key = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  /// Load todos from local storage. Call once at app startup.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null && data.isNotEmpty) {
      _todos.clear();
      _todos.addAll(decodeTodos(data));
      // Restore _idSeq to avoid ID collisions
      for (final todo in _todos) {
        _idSeq++;
        for (final sub in todo.subtasks) {
          _idSeq++;
        }
      }
      notifyListeners();
    }
  }

  /// Persist current todos to local storage.
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, encodeTodos(_todos));
  }

  void add(
    String title, {
    List<String> subtaskTitles = const [],
    DateTime? dueDate,
  }) {
    _todos.add(
      Todo(
        id: _newId(),
        title: title,
        subtasks: [
          for (final subtaskTitle in subtaskTitles)
            Subtask(id: _newId(), title: subtaskTitle),
        ],
        dueDate: dueDate,
      ),
    );
    notifyListeners();
    _save();
  }

  void update(
    Todo todo, {
    String? title,
    List<String>? subtaskTitles,
    DateTime? dueDate,
  }) {
    final index = _indexOf(todo.id);
    if (index == -1) return;
    final current = _todos[index];

    List<Subtask>? subtasks;
    if (subtaskTitles != null) {
      subtasks = [
        for (var i = 0; i < subtaskTitles.length; i++)
          i < current.subtasks.length
              ? current.subtasks[i].copyWith(title: subtaskTitles[i])
              : Subtask(id: _newId(), title: subtaskTitles[i]),
      ];
    }

    _todos[index] = current.copyWith(
      title: title,
      subtasks: subtasks,
      dueDate: dueDate,
    );
    notifyListeners();
    _save();
  }

  void toggle(Todo todo) {
    final index = _indexOf(todo.id);
    if (index == -1) return;
    _todos[index] = todo.copyWith(isCompleted: !todo.isCompleted);
    notifyListeners();
    _save();
  }

  void remove(String id) {
    _todos.removeWhere((t) => t.id == id);
    notifyListeners();
    _save();
  }

  void addSubtask(String todoId, String title) {
    final index = _indexOf(todoId);
    if (index == -1) return;
    final current = _todos[index];
    _todos[index] = current.copyWith(
      subtasks: [
        ...current.subtasks,
        Subtask(id: _newId(), title: title),
      ],
    );
    notifyListeners();
    _save();
  }

  void toggleSubtask(String todoId, String subtaskId) {
    final index = _indexOf(todoId);
    if (index == -1) return;
    final todo = _todos[index];
    final newSubtasks = todo.subtasks.map((s) {
      if (s.id == subtaskId) return s.copyWith(isCompleted: !s.isCompleted);
      return s;
    }).toList();
    _todos[index] = todo.copyWith(subtasks: newSubtasks);
    _syncSubtaskCompletion(index);
    notifyListeners();
    _save();
  }

  void removeSubtask(String todoId, String subtaskId) {
    final index = _indexOf(todoId);
    if (index == -1) return;
    final todo = _todos[index];
    _todos[index] = todo.copyWith(
      subtasks: todo.subtasks.where((s) => s.id != subtaskId).toList(),
    );
    _syncSubtaskCompletion(index);
    notifyListeners();
    _save();
  }

  /// Auto-sync parent todo isCompleted when all subtasks are done.
  void _syncSubtaskCompletion(int todoIndex) {
    final todo = _todos[todoIndex];
    if (todo.subtasks.isEmpty) return;
    final allDone = todo.subtasks.every((s) => s.isCompleted);
    if (allDone != todo.isCompleted) {
      _todos[todoIndex] = todo.copyWith(isCompleted: allDone);
    }
  }

  int get completedCount => _todos.where((t) => t.isCompleted).length;

  int get subtaskCount =>
      _todos.fold(0, (sum, todo) => sum + todo.subtasks.length);

  int get completedSubtaskCount => _todos.fold(
    0,
    (sum, todo) => sum + todo.subtasks.where((s) => s.isCompleted).length,
  );

  int get totalUnits => _todos.length + subtaskCount;

  int get completedUnits => completedCount + completedSubtaskCount;

  /// Set or clear the due date for a specific todo.
  void setDueDate(String todoId, DateTime? dueDate) {
    final index = _indexOf(todoId);
    if (index == -1) return;
    _todos[index] = _todos[index].copyWith(dueDate: dueDate);
    notifyListeners();
    _save();
  }
}
