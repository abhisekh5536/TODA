import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/todo.dart';
import '../stores/todo_store.dart';
import '../theme/app_theme.dart';
import '../utils/date_labels.dart';
import '../widgets/backdrop.dart';
import '../widgets/gradient_button.dart';
import '../widgets/task_sheet.dart';

class TodoDetailScreen extends StatelessWidget {
  const TodoDetailScreen({
    super.key,
    required this.store,
    required this.todoId,
  });

  final TodoStore store;
  final String todoId;

  Future<void> _edit(BuildContext context, Todo todo) async {
    final draft = await showTaskSheet(context, todo: todo);
    if (draft == null || draft.title.isEmpty) return;
    store.update(todo, title: draft.title, subtaskTitles: draft.subtasks);
  }

  void _delete(BuildContext context, Todo todo) {
    store.remove(todo.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayStyleFor(theme.brightness),
      child: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(child: AppBackdrop()),
            SafeArea(
              child: ListenableBuilder(
                listenable: store,
                builder: (context, _) {
                  final todo = store.byId(todoId);
                  if (todo == null) return const SizedBox.shrink();

                  return Column(
                    children: [
                      _DetailHeader(
                        onBack: () => Navigator.pop(context),
                        onEdit: () => _edit(context, todo),
                        onDelete: () => _delete(context, todo),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 6, 24, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _StatusOrb(
                                todo: todo,
                                onToggle: () => store.toggle(todo),
                              ),
                              const SizedBox(height: 30),
                              Text(
                                todo.title,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                  height: 1.2,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 22),
                              _MetaCard(todo: todo),
                              const SizedBox(height: 24),
                              _SubtasksSection(
                                todo: todo,
                                onToggle: (subtask) =>
                                    store.toggleSubtask(todo.id, subtask.id),
                                onRemove: (subtask) =>
                                    store.removeSubtask(todo.id, subtask.id),
                                onAdd: (title) =>
                                    store.addSubtask(todo.id, title),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _DetailActions(
                        todo: todo,
                        onToggle: () => store.toggle(todo),
                        onDelete: () => _delete(context, todo),
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
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: 'Back',
            onTap: onBack,
          ),
          const Spacer(),
          _CircleIconButton(
            icon: Icons.edit_outlined,
            tooltip: 'Edit task',
            onTap: onEdit,
          ),
          const SizedBox(width: 10),
          _CircleIconButton(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Delete task',
            tint: AppColors.danger(Theme.of(context).brightness).colors.first,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.tint,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = tint ?? theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Material(
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        icon: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

class _StatusOrb extends StatelessWidget {
  const _StatusOrb({required this.todo, required this.onToggle});

  final Todo todo;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.sand : AppColors.sage;

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: todo.isCompleted
                    ? AppColors.primary(
                        isDark ? Brightness.dark : Brightness.light,
                      )
                    : null,
                color: todo.isCompleted
                    ? null
                    : (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.04,
                      ),
                border: Border.all(
                  color: todo.isCompleted
                      ? Colors.transparent
                      : accent.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: todo.isCompleted
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.35),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ]
                    : null,
              ),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutBack,
                scale: todo.isCompleted ? 1 : 0,
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: todo.isCompleted
                  ? AppColors.primary(
                      isDark ? Brightness.dark : Brightness.light,
                    )
                  : null,
              color: todo.isCompleted ? null : accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: todo.isCompleted
                    ? Colors.transparent
                    : accent.withValues(alpha: 0.45),
              ),
            ),
            child: Text(
              todo.isCompleted ? 'Completed' : 'Active',
              style: TextStyle(
                color: todo.isCompleted ? Colors.white : accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.todo});

  final Todo todo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.045) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _MetaRow(
            icon: Icons.schedule_rounded,
            tint: isDark ? AppColors.sand : const Color(0xFFA8863D),
            label: 'Added',
            value: timeLabel(todo.createdAt),
          ),
          const SizedBox(height: 12),
          _MetaRow(
            icon: Icons.flag_outlined,
            tint: isDark ? AppColors.sand : AppColors.sage,
            label: 'Status',
            value: todo.isCompleted ? 'Completed' : 'In progress',
          ),
          const SizedBox(height: 12),
          _MetaRow(
            icon: Icons.text_fields_rounded,
            tint: isDark ? AppColors.terracotta : AppColors.gold,
            label: 'Length',
            value: '${todo.title.length} characters',
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.tint,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tint.withValues(alpha: 0.14),
          ),
          child: Icon(icon, size: 18, color: tint),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.55),
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DetailActions extends StatelessWidget {
  const _DetailActions({
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final danger = AppColors.danger(
      isDark ? Brightness.dark : Brightness.light,
    ).colors.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GradientButton(
            expanded: true,
            label: todo.isCompleted ? 'Mark as active' : 'Mark as done',
            icon: todo.isCompleted ? Icons.undo_rounded : Icons.check_rounded,
            onPressed: onToggle,
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Delete task'),
            style: TextButton.styleFrom(foregroundColor: danger),
          ),
        ],
      ),
    );
  }
}

class _SubtasksSection extends StatefulWidget {
  const _SubtasksSection({
    required this.todo,
    required this.onToggle,
    required this.onRemove,
    required this.onAdd,
  });

  final Todo todo;
  final ValueChanged<Subtask> onToggle;
  final ValueChanged<Subtask> onRemove;
  final ValueChanged<String> onAdd;

  @override
  State<_SubtasksSection> createState() => _SubtasksSectionState();
}

class _SubtasksSectionState extends State<_SubtasksSection> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _adding = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onAdd(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.sand : AppColors.sage;
    final subtasks = widget.todo.subtasks;
    final done = subtasks.where((s) => s.isCompleted).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Subtasks',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 10),
            if (subtasks.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$done/${subtasks.length}',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (subtasks.isEmpty && !_adding)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.04,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.08,
                ),
              ),
            ),
            child: Text(
              'No subtasks yet — break this task into micro steps.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
        for (final subtask in subtasks)
          _SubtaskRow(
            subtask: subtask,
            accent: accent,
            onToggle: () => widget.onToggle(subtask),
            onRemove: () => widget.onRemove(subtask),
          ),
        if (_adding)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'Micro task',
                      isDense: true,
                      filled: true,
                      fillColor: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.04),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.10),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _submit,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.primary(theme.brightness),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary(
                            theme.brightness,
                          ).colors.first.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          TextButton.icon(
            onPressed: () => setState(() => _adding = true),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add subtask'),
            style: TextButton.styleFrom(
              foregroundColor: accent,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

class _SubtaskRow extends StatelessWidget {
  const _SubtaskRow({
    required this.subtask,
    required this.accent,
    required this.onToggle,
    required this.onRemove,
  });

  final Subtask subtask;
  final Color accent;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.045) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  width: 23,
                  height: 23,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: subtask.isCompleted
                        ? AppColors.primary(theme.brightness)
                        : null,
                    border: Border.all(
                      color: subtask.isCompleted
                          ? Colors.transparent
                          : theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.45,
                            ),
                      width: 1.5,
                    ),
                  ),
                ),
                AnimatedScale(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  scale: subtask.isCompleted ? 1 : 0,
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              style: theme.textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w600,
                color: subtask.isCompleted
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.32)
                    : theme.colorScheme.onSurface,
                decoration: subtask.isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                decorationColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.4,
                ),
              ),
              child: Text(subtask.title),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Remove subtask',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.close_rounded,
              size: 17,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.30),
            ),
          ),
        ],
      ),
    );
  }
}
