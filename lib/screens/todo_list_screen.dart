import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/todo.dart';
import '../stores/todo_store.dart';
import '../theme/app_theme.dart';
import '../widgets/backdrop.dart';
import '../widgets/gradient_button.dart';
import '../widgets/progress_ring.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/task_sheet.dart';
import '../widgets/todo_tile.dart';
import 'todo_detail_screen.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({
    super.key,
    required this.store,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final TodoStore store;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  Filter _filter = Filter.all;

  TodoStore get _store => widget.store;

  Future<void> _showTaskSheet({Todo? todo}) async {
    final draft = await showTaskSheet(context, todo: todo);
    if (draft == null || draft.title.isEmpty || !mounted) return;
    if (todo == null) {
      _store.add(draft.title, subtaskTitles: draft.subtasks);
    } else {
      _store.update(todo, title: draft.title, subtaskTitles: draft.subtasks);
    }
  }

  void _openSettings() {
    showSettingsSheet(
      context,
      current: widget.themeMode,
      onChanged: widget.onThemeModeChanged,
    );
  }

  void _openDetail(Todo todo) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: TodoDetailScreen(store: _store, todoId: todo.id),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayStyleFor(Theme.of(context).brightness),
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: AppBackdrop()),
            SafeArea(
              child: ListenableBuilder(
                listenable: _store,
                builder: (context, _) {
                  final todos = _store.filtered(_filter);
                  return Column(
                    children: [
                      _Header(onSettings: _openSettings),
                      _ProgressCard(store: _store),
                      _FilterBar(
                        store: _store,
                        current: _filter,
                        onChanged: (value) => setState(() => _filter = value),
                      ),
                      Expanded(
                        child: todos.isEmpty
                            ? _EmptyState(
                                filter: _filter,
                                onAdd: () => _showTaskSheet(),
                              )
                            : ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  8,
                                ),
                                itemCount: todos.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 0),
                                itemBuilder: (context, index) {
                                  final todo = todos[index];
                                  return TodoTile(
                                    key: ValueKey(todo.id),
                                    todo: todo,
                                    onToggle: () => _store.toggle(todo),
                                    onEdit: () => _showTaskSheet(todo: todo),
                                    onDelete: () => _store.remove(todo.id),
                                    onOpen: () => _openDetail(todo),
                                  );
                                },
                              ),
                      ),
                      _Footer(store: _store),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: _FloatingAddButton(onPressed: () => _showTaskSheet()),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final greeting = switch (now.hour) {
      < 12 => 'Good morning',
      < 18 => 'Good afternoon',
      _ => 'Good evening',
    };
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSettings,
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_rounded),
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppColors.primary(Theme.of(context).brightness),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary(
                    Theme.of(context).brightness,
                  ).colors.first.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.store});

  final TodoStore store;

  static String _motivation(double progress) {
    if (progress >= 1) return 'Everything done. Beautiful.';
    if (progress >= 0.5) return 'So close — finish strong.';
    if (progress > 0) return 'Every task crossed brings calm.';
    return 'Pick one thing. Start there.';
  }

  @override
  Widget build(BuildContext context) {
    final total = store.totalUnits;
    final done = store.completedUnits;
    final progress = total == 0 ? 0.0 : done / total;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primary(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary(
              Theme.of(context).brightness,
            ).colors.first.withValues(alpha: 0.38),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -42,
            right: -22,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Row(
            children: [
              ProgressRing(
                progress: progress,
                size: 76,
                strokeWidth: 7,
                gradient: AppColors.ring(Theme.of(context).brightness),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$done',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '/$total',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$done of $total done',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _motivation(progress),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (store.subtaskCount > 0) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${store.completedSubtaskCount} of ${store.subtaskCount} micro tasks done',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 13),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.22),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.store,
    required this.current,
    required this.onChanged,
  });

  final TodoStore store;
  final Filter current;
  final ValueChanged<Filter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
      child: Row(
        children: [
          Expanded(
            child: _FilterPill(
              label: 'All',
              count: store.todos.length,
              selected: current == Filter.all,
              onTap: () => onChanged(Filter.all),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _FilterPill(
              label: 'Active',
              count: store.todos.length - store.completedCount,
              selected: current == Filter.active,
              onTap: () => onChanged(Filter.active),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _FilterPill(
              label: 'Done',
              count: store.completedCount,
              selected: current == Filter.completed,
              onTap: () => onChanged(Filter.completed),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          gradient: selected
              ? AppColors.primary(Theme.of(context).brightness)
              : null,
          color: selected
              ? null
              : Colors.white.withValues(alpha: isDark ? 0.05 : 0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.10,
                  ),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary(
                      Theme.of(context).brightness,
                    ).colors.first.withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6.5,
                vertical: 1.5,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.store});

  final TodoStore store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
      child: Text(
        '${store.completedCount} of ${store.todos.length} done · tap to view · swipe right to complete, left to delete',
        textAlign: TextAlign.center,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter, required this.onAdd});

  final Filter filter;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.sand : AppColors.sage;
    final (title, subtitle) = switch (filter) {
      Filter.all => (
        'No tasks yet',
        'Your list is empty. Add your first task.',
      ),
      Filter.active => ('All clear', 'Nothing active right now. Enjoy it.'),
      Filter.completed => ('Nothing done yet', 'Check off your first task.'),
    };

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accent.withValues(alpha: isDark ? 0.45 : 0.28),
                  accent.withValues(alpha: 0.02),
                ],
              ),
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 44,
              color: accent.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 28),
          GradientButton(
            label: 'Add task',
            icon: Icons.add_rounded,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _FloatingAddButton extends StatelessWidget {
  const _FloatingAddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final gradient = AppColors.accent(Theme.of(context).brightness);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: gradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.45),
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}
