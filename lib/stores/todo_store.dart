import 'package:flutter/material.dart';

import '../models/todo.dart';

enum Filter { all, active, completed }

class TodoStore extends ChangeNotifier {
  final List<Todo> _todos = [];
  int _idSeq = 0;

  String _newId() => '${DateTime.now().microsecondsSinceEpoch}-${_idSeq++}';

  List<Todo> get todos => List.unmodifiable(_todos);

  Todo? byId(String id) {
    for (final todo in _todos) {
      if (todo.id == id) return todo;
    }
    return null;
  }

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

  void add(String title, {List<String> subtaskTitles = const []}) {
    _todos.add(
      Todo(
        id: _newId(),
        title: title,
        subtasks: [
          for (final subtaskTitle in subtaskTitles)
            Subtask(id: _newId(), title: subtaskTitle),
        ],
      ),
    );
    notifyListeners();
  }

  void update(Todo todo, {String? title, List<String>? subtaskTitles}) {
    final index = _todos.indexWhere((t) => t.id == todo.id);
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

    _todos[index] = current.copyWith(title: title, subtasks: subtasks);
    notifyListeners();
  }

  void toggle(Todo todo) {
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index == -1) return;
    _todos[index] = todo.copyWith(isCompleted: !todo.isCompleted);
    notifyListeners();
  }

  void remove(String id) {
    _todos.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void addSubtask(String todoId, String title) {
    final todo = byId(todoId);
    if (todo == null) return;
    todo.subtasks.add(Subtask(id: _newId(), title: title));
    notifyListeners();
  }

  void toggleSubtask(String todoId, String subtaskId) {
    final todo = byId(todoId);
    if (todo == null) return;
    final index = todo.subtasks.indexWhere((s) => s.id == subtaskId);
    if (index == -1) return;
    todo.subtasks[index] = todo.subtasks[index].copyWith(
      isCompleted: !todo.subtasks[index].isCompleted,
    );
    _syncSubtaskCompletion(todo);
    notifyListeners();
  }

  void removeSubtask(String todoId, String subtaskId) {
    final todo = byId(todoId);
    if (todo == null) return;
    todo.subtasks.removeWhere((s) => s.id == subtaskId);
    _syncSubtaskCompletion(todo);
    notifyListeners();
  }

  void _syncSubtaskCompletion(Todo todo) {
    if (todo.subtasks.isEmpty) return;
    final allDone = todo.subtasks.every((s) => s.isCompleted);
    if (allDone != todo.isCompleted) {
      todo.isCompleted = allDone;
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
}
