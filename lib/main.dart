import 'package:flutter/material.dart';

import 'screens/todo_list_screen.dart';
import 'stores/todo_store.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TodoApp());
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  ThemeMode _mode = ThemeMode.dark;
  final TodoStore _store = TodoStore();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initStore();
  }

  Future<void> _initStore() async {
    await _store.load();
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Todo List',
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppTheme.scrollBehavior,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _mode,
      home: TodoListScreen(
        store: _store,
        themeMode: _mode,
        onThemeModeChanged: (mode) => setState(() => _mode = mode),
      ),
    );
  }
}
