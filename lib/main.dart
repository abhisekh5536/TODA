import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash_screen.dart';
import 'screens/todo_list_screen.dart';
import 'services/notification_service.dart';
import 'stores/todo_store.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService.init();
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

  static const _themeKey = 'todo_app_theme_mode';

  @override
  void initState() {
    super.initState();
    _initStore();
  }

  Future<void> _initStore() async {
    // Load persisted theme mode
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey);
    if (themeIndex != null && themeIndex >= 0 && themeIndex <= 1) {
      _mode = ThemeMode.values[themeIndex];
    }

    await _store.load();
    // Let the Flutter splash animation finish (title, checkmark, bar) before
    // transitioning to the main app — keeps the experience seamless.
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) setState(() => _ready = true);

    // Request notification permission after the app is visible
    if (mounted) NotificationService.requestPermission();
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    if (mounted) setState(() => _mode = mode);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const SplashScreen(),
      );
    }

    return MaterialApp(
      title: 'TODA',
      debugShowCheckedModeBanner: false,
      scrollBehavior: AppTheme.scrollBehavior,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _mode,
      home: TodoListScreen(
        store: _store,
        themeMode: _mode,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}
