import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/todo.dart';
import '../stores/todo_store.dart';
import '../theme/app_theme.dart';
import '../utils/date_labels.dart';
import 'todo_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    required this.store,
  });

  final TodoStore store;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  TodoStore get _store => widget.store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayStyleFor(theme.brightness),
      child: Scaffold(
        body: Stack(
          children: [
            // Gradient background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF0F3040), const Color(0xFF1A3A4A)]
                        : [const Color(0xFFF7F4ED), const Color(0xFFEEE9DF)],
                  ),
                ),
              ),
            ),
            // Decorative glow circles
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? AppColors.sand : AppColors.sage)
                      .withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -50,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? AppColors.terracotta : AppColors.gold)
                      .withValues(alpha: 0.06),
                ),
              ),
            ),
            SafeArea(
              child: ListenableBuilder(
                listenable: _store,
                builder: (context, _) {
                  final selectedTodos = _store.todosForDate(_selectedDay);
                  final eventMap = _store.taskCountsForMonth(_focusedDay);

                  return Column(
                    children: [
                      // Header
                      _CalendarHeader(
                        focusedDay: _focusedDay,
                        onBack: () => Navigator.pop(context),
                      ),
                      // Calendar
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.06),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.2 : 0.06),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: TableCalendar(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) =>
                              isSameDay(day, _selectedDay),
                          calendarFormat: _calendarFormat,
                          onFormatChanged: (format) {
                            if (format != _calendarFormat) {
                              setState(() => _calendarFormat = format);
                            }
                          },
                          onDaySelected: (selected, focused) {
                            setState(() {
                              _selectedDay = selected;
                              _focusedDay = focused;
                            });
                          },
                          onPageChanged: (focused) {
                            setState(() => _focusedDay = focused);
                          },
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, date, events) {
                              final count = eventMap[DateTime(
                                date.year,
                                date.month,
                                date.day,
                              )];
                              if (count == null) return const SizedBox.shrink();
                              return Positioned(
                                bottom: 1,
                                child: _DayMarker(
                                  count: count,
                                  isDark: isDark,
                                ),
                              );
                            },
                            selectedBuilder: (context, date, focused) {
                              return _SelectedDayCell(
                                date: date,
                                isDark: isDark,
                              );
                            },
                            todayBuilder: (context, date, focused) {
                              return _TodayCell(
                                date: date,
                                isDark: isDark,
                                isSelected: isSameDay(date, _selectedDay),
                              );
                            },
                            defaultBuilder: (context, date, focused) {
                              final hasTasks = eventMap.containsKey(
                                DateTime(date.year, date.month, date.day),
                              );
                              return _DefaultDayCell(
                                date: date,
                                isDark: isDark,
                                hasTasks: hasTasks,
                              );
                            },
                            outsideBuilder: (context, date, focused) {
                              return Center(
                                child: Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.18),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                          headerVisible: false,
                          daysOfWeekHeight: 44,
                          rowHeight: 52,
                          daysOfWeekStyle: DaysOfWeekStyle(
                            weekdayStyle: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.45),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                            weekendStyle: TextStyle(
                              color: (isDark ? AppColors.sand : AppColors.sage)
                                  .withValues(alpha: 0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          calendarStyle: CalendarStyle(
                            cellMargin: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            outsideDaysVisible: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Format toggle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _FormatChip(
                              label: 'Week',
                              selected: _calendarFormat ==
                                  CalendarFormat.week,
                              onTap: () => setState(
                                () => _calendarFormat = CalendarFormat.week,
                              ),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 10),
                            _FormatChip(
                              label: '2 Weeks',
                              selected: _calendarFormat ==
                                  CalendarFormat.twoWeeks,
                              onTap: () => setState(
                                () =>
                                    _calendarFormat = CalendarFormat.twoWeeks,
                              ),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 10),
                            _FormatChip(
                              label: 'Month',
                              selected: _calendarFormat ==
                                  CalendarFormat.month,
                              onTap: () => setState(
                                () => _calendarFormat = CalendarFormat.month,
                              ),
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Selected date label
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Text(
                              _selectedDateLabel(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            if (selectedTodos.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient:
                                      AppColors.primary(theme.brightness),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${selectedTodos.length} task${selectedTodos.length == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Task list for selected day
                      Expanded(
                        child: selectedTodos.isEmpty
                            ? _NoTasksForDate(
                                date: _selectedDay,
                                isDark: isDark,
                              )
                            : ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                                itemCount: selectedTodos.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final todo = selectedTodos[index];
                                  return _CalendarTaskCard(
                                    todo: todo,
                                    isDark: isDark,
                                    onTap: () => _openDetail(todo),
                                    onToggle: () => _store.toggle(todo),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _selectedDateLabel() {
    final now = DateTime.now();
    if (isSameDay(_selectedDay, now)) return 'Today';
    final yesterday = now.subtract(const Duration(days: 1));
    if (isSameDay(_selectedDay, yesterday)) return 'Yesterday';
    final tomorrow = now.add(const Duration(days: 1));
    if (isSameDay(_selectedDay, tomorrow)) return 'Tomorrow';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[_selectedDay.month - 1]} ${_selectedDay.day}, ${_selectedDay.year}';
  }

  void _openDetail(Todo todo) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
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
}

// ─── Header ────────────────────────────────────────────────────────

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({required this.focusedDay, required this.onBack});

  final DateTime focusedDay;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _CircleButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
            isDark: isDark,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calendar',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${months[focusedDay.month - 1]} ${focusedDay.year}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppColors.accent(theme.brightness),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent(theme.brightness).colors.first
                      .withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Circle Button ────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap, required this.isDark});

  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        tooltip: 'Back',
      ),
    );
  }
}

// ─── Day Marker (dots below date cell) ────────────────────────────

class _DayMarker extends StatelessWidget {
  const _DayMarker({required this.count, required this.isDark});

  final int count;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.sand : AppColors.sage;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        if (count > 1) ...[
          const SizedBox(width: 3),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppColors.terracotta : AppColors.gold,
            ),
          ),
        ],
        if (count > 2) ...[
          const SizedBox(width: 3),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF8FA28A) : const Color(0xFFC8A96B),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Selected Day Cell ─────────────────────────────────────────────

class _SelectedDayCell extends StatelessWidget {
  const _SelectedDayCell({required this.date, required this.isDark});

  final DateTime date;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        gradient: AppColors.primary(isDark ? Brightness.dark : Brightness.light),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary(isDark ? Brightness.dark : Brightness.light)
                .colors.first
                .withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '${date.day}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ─── Today Cell ───────────────────────────────────────────────────

class _TodayCell extends StatelessWidget {
  const _TodayCell({required this.date, required this.isDark, required this.isSelected});

  final DateTime date;
  final bool isDark;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.sand : AppColors.sage;
    if (isSelected) {
      return _SelectedDayCell(date: date, isDark: isDark);
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent, width: 2),
      ),
      child: Center(
        child: Text(
          '${date.day}',
          style: TextStyle(
            color: accent,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ─── Default Day Cell ────────────────────────────────────────────

class _DefaultDayCell extends StatelessWidget {
  const _DefaultDayCell({required this.date, required this.isDark, required this.hasTasks});

  final DateTime date;
  final bool isDark;
  final bool hasTasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWeekend = date.weekday == 6 || date.weekday == 7;
    return Center(
      child: Text(
        '${date.day}',
        style: TextStyle(
          color: isWeekend
              ? (isDark ? AppColors.sand : AppColors.sage).withValues(alpha: 0.8)
              : theme.colorScheme.onSurface.withValues(alpha: hasTasks ? 0.9 : 0.55),
          fontSize: 16,
          fontWeight: hasTasks ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Format Toggle Chip ───────────────────────────────────────────

class _FormatChip extends StatelessWidget {
  const _FormatChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: selected
              ? AppColors.primary(isDark ? Brightness.dark : Brightness.light)
              : null,
          color: selected
              ? null
              : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary(isDark ? Brightness.dark : Brightness.light)
                        .colors.first
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── No Tasks for Date ────────────────────────────────────────────

class _NoTasksForDate extends StatelessWidget {
  const _NoTasksForDate({required this.date, required this.isDark});

  final DateTime date;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = isDark ? AppColors.sand : AppColors.sage;
    final now = DateTime.now();
    final isPast = DateTime(date.year, date.month, date.day)
        .isBefore(DateTime(now.year, now.month, now.day));

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accent.withValues(alpha: isDark ? 0.3 : 0.18),
                  accent.withValues(alpha: 0.02),
                ],
              ),
            ),
            child: Icon(
              isPast
                  ? Icons.event_available_rounded
                  : Icons.event_busy_rounded,
              size: 38,
              color: accent.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isPast ? 'Nothing was due' : 'No tasks due',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isPast ? 'This day was clear.' : 'This day is free.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Calendar Task Card ────────────────────────────────────────────

class _CalendarTaskCard extends StatelessWidget {
  const _CalendarTaskCard({
    required this.todo,
    required this.isDark,
    required this.onTap,
    required this.onToggle,
  });

  final Todo todo;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = isDark ? AppColors.sand : AppColors.sage;
    final overdue = todo.isOverdue;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.045)
              : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: overdue
                ? AppColors.danger(isDark ? Brightness.dark : Brightness.light)
                    .colors
                    .first
                    .withValues(alpha: 0.45)
                : (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.08),
            width: overdue ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status circle
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: todo.isCompleted
                      ? AppColors.primary(isDark ? Brightness.dark : Brightness.light)
                      : null,
                  border: Border.all(
                    color: todo.isCompleted
                        ? Colors.transparent
                        : overdue
                            ? AppColors.danger(isDark ? Brightness.dark : Brightness.light)
                                .colors
                                .first
                                .withValues(alpha: 0.6)
                            : theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.4),
                    width: 1.6,
                  ),
                ),
                child: todo.isCompleted
                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            // Title + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    todo.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: todo.isCompleted
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                          : theme.colorScheme.onSurface,
                      decoration: todo.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: theme.colorScheme.onSurface
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (overdue && !todo.isCompleted) ...[
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 12,
                          color: AppColors.danger(isDark ? Brightness.dark : Brightness.light)
                              .colors
                              .first,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Overdue',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger(isDark ? Brightness.dark : Brightness.light)
                                .colors
                                .first,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (todo.subtasks.isNotEmpty) ...[
                        Icon(
                          Icons.checklist_rounded,
                          size: 12,
                          color: accent.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${todo.subtasks.where((s) => s.isCompleted).length}/${todo.subtasks.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: accent.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            ),
          ],
        ),
      ),
    );
  }
}
