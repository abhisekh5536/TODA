import 'package:flutter/material.dart';

import '../models/todo.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';

class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.subtasks,
    this.dueDate,
  });

  final String title;
  final List<String> subtasks;
  final DateTime? dueDate;
}

Future<TaskDraft?> showTaskSheet(BuildContext context, {Todo? todo}) {
  return showModalBottomSheet<TaskDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _TaskSheet(todo: todo),
  );
}

class _TaskSheet extends StatefulWidget {
  const _TaskSheet({this.todo});

  final Todo? todo;

  @override
  State<_TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends State<_TaskSheet> {
  late final TextEditingController _controller;
  late final bool _isEdit;
  late final List<TextEditingController> _subControllers;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.todo != null;
    _controller = TextEditingController(text: widget.todo?.title ?? '');
    _dueDate = widget.todo?.dueDate ?? DateTime.now();
    _subControllers = [
      for (final subtask in widget.todo?.subtasks ?? const <Subtask>[])
        TextEditingController(text: subtask.title),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final controller in _subControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addSubtaskField() {
    setState(() => _subControllers.add(TextEditingController()));
  }

  void _removeSubtaskField(int index) {
    setState(() => _subControllers.removeAt(index).dispose());
  }

  TaskDraft? _draft() {
    final title = _controller.text.trim();
    if (title.isEmpty) return null;
    return TaskDraft(
      title: title,
      subtasks: [
        for (final controller in _subControllers)
          if (controller.text.trim().isNotEmpty) controller.text.trim(),
      ],
      dueDate: _dueDate,
    );
  }

  void _submit() {
    final draft = _draft();
    if (draft == null) return;
    Navigator.pop(context, draft);
  }

  Future<void> _pickDate() async {
    final initial = _dueDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return Theme(
          data: theme.copyWith(
            colorScheme: ColorScheme.dark(
              primary: isDark ? AppColors.sand : AppColors.sage,
              onPrimary: isDark ? const Color(0xFF3A1A0E) : Colors.white,
              surface: isDark ? const Color(0xFF1A3A4A) : const Color(0xFFF7F4ED),
              onSurface: isDark ? const Color(0xFFF4ECD1) : const Color(0xFF2C3525),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _clearDate() {
    setState(() => _dueDate = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.sand : AppColors.sage;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(
            top: BorderSide(
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.06,
              ),
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _isEdit ? 'Edit task' : 'New task',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  minLines: 1,
                  maxLines: 4,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'What needs to be done?',
                    filled: true,
                    fillColor: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.04),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.10),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Due date picker
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Due date',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_dueDate != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_rounded,
                          size: 18,
                          color: accent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _dateLabel(_dueDate!),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _clearDate,
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(
                      _dueDate != null ? 'Change date' : 'Set due date',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.format_list_bulleted_rounded,
                      size: 18,
                      color: accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Subtasks',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    if (_subControllers.isNotEmpty)
                      Text(
                        '${_subControllers.where((c) => c.text.trim().isNotEmpty).length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_subControllers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Break it down into micro tasks.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
                      ),
                    ),
                  ),
                for (var i = 0; i < _subControllers.length; i++)
                  _SubtaskFieldRow(
                    controller: _subControllers[i],
                    accent: accent,
                    onSubmitted: (_) => _addSubtaskField(),
                    onRemove: () => _removeSubtaskField(i),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addSubtaskField,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add subtask'),
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GradientButton(
                  label: _isEdit ? 'Save changes' : 'Add task',
                  icon: _isEdit ? Icons.check_rounded : Icons.add_rounded,
                  expanded: true,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Tomorrow';
    }
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _SubtaskFieldRow extends StatelessWidget {
  const _SubtaskFieldRow({
    required this.controller,
    required this.accent,
    required this.onSubmitted,
    required this.onRemove,
  });

  final TextEditingController controller;
  final Color accent;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 1,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Micro task',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  fontSize: 13.5,
                ),
              ),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Remove subtask',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.close_rounded,
              size: 17,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}
