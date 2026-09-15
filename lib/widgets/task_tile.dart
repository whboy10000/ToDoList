import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/app_state.dart';
import '../pages/task_edit_sheet.dart';

/// 单条任务的列表项
class TaskTile extends StatelessWidget {
  final AppState state;
  final Task task;
  final bool showMenu;

  const TaskTile({
    super.key,
    required this.state,
    required this.task,
    this.showMenu = true,
  });

  String _dueText() {
    final d = task.due!;
    final now = DateTime.now();
    String two(DateTime d) => '${d.month}/${d.day}';
    if (task.dueHasTime) {
      final hh = d.hour.toString().padLeft(2, '0');
      final mm = d.minute.toString().padLeft(2, '0');
      final sameDay = d.year == now.year && d.month == now.month && d.day == now.day;
      return sameDay ? '今天 $hh:$mm' : '${two(d)} $hh:$mm';
    }
    final today = DateTime(now.year, now.month, now.day);
    final dd = DateTime(d.year, d.month, d.day);
    final diff = dd.difference(today).inDays;
    if (diff == 0) return '今天';
    if (diff == 1) return '明天';
    if (diff == -1) return '昨天';
    return two(d);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cat = state.categoryOf(task.categoryId);
    final done = task.isDone;

    Color? dueColor;
    if (task.isOverdue) {
      dueColor = theme.colorScheme.error;
    } else if (task.isDueToday && !done) {
      dueColor = Colors.orange;
    }

    return ListTile(
      leading: Checkbox(
        value: done,
        onChanged: (_) => state.toggleDone(task.id),
      ),
      title: Text(
        task.title,
        style: TextStyle(
          decoration: done ? TextDecoration.lineThrough : null,
          color: done ? theme.disabledColor : null,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: _buildMeta(theme, cat, dueColor),
      trailing: showMenu ? _buildMenu(context) : null,
      onTap: () => showTaskEditSheet(context, state, task),
    );
  }

  Widget? _buildMeta(ThemeData theme, Category? cat, Color? dueColor) {
    final chips = <Widget>[];
    final metaStyle = theme.textTheme.bodySmall;

    if (task.due != null) {
      chips.add(_metaChip(
        icon: task.isOverdue ? Icons.error_outline : Icons.schedule,
        text: _dueText(),
        color: dueColor,
        style: metaStyle,
      ));
    }
    if (task.priority != Priority.none) {
      chips.add(_metaChip(
        icon: Icons.flag,
        text: task.priority.label,
        color: task.priority.color,
        style: metaStyle,
      ));
    }
    if (cat != null) {
      chips.add(_metaChip(
        icon: Icons.lens,
        iconSize: 8,
        text: cat.name,
        color: cat.color,
        style: metaStyle,
      ));
    }
    if (task.subtasks.isNotEmpty) {
      chips.add(_metaChip(
        icon: Icons.checklist,
        text: '${task.subtasksDone}/${task.subtasks.length}',
        color: theme.hintColor,
        style: metaStyle,
      ));
    }
    if (task.repeat != TaskRepeat.none) {
      chips.add(_metaChip(
        icon: Icons.repeat,
        text: task.repeat.label,
        color: theme.hintColor,
        style: metaStyle,
      ));
    }
    if (task.focusSessions > 0) {
      chips.add(_metaChip(
        icon: Icons.local_fire_department_outlined,
        text: '${task.focusSessions}',
        color: theme.hintColor,
        style: metaStyle,
      ));
    }
    for (final tag in task.tags) {
      chips.add(_metaChip(
        icon: Icons.tag,
        text: tag,
        color: theme.colorScheme.primary,
        style: metaStyle,
      ));
    }
    if (task.note.isNotEmpty) {
      chips.add(_metaChip(
        icon: Icons.notes,
        text: '备注',
        color: theme.hintColor,
        style: metaStyle,
      ));
    }
    if (chips.isEmpty) return null;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: chips),
    );
  }

  Widget _metaChip({
    required IconData icon,
    required String text,
    Color? color,
    double iconSize = 14,
    TextStyle? style,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 3),
          Text(text, style: style?.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '更多操作',
      onSelected: (v) {
        switch (v) {
          case 'archive':
            state.archiveTask(task.id);
          case 'trash':
            state.trashTask(task.id);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('已移入回收站'),
              action: SnackBarAction(label: '撤销', onPressed: state.undo),
            ));
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'archive', child: Text('归档')),
        PopupMenuItem(value: 'trash', child: Text('移入回收站')),
      ],
    );
  }
}
