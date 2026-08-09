import 'package:flutter/material.dart';

import 'screens/todo_list_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  ThemeMode _mode = ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo List',
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppTheme.scrollBehavior,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _mode,
      home: TodoListScreen(
        themeMode: _mode,
        onThemeModeChanged: (mode) => setState(() => _mode = mode),
      ),
    );
  }
}
