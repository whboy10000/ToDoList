import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/app_state.dart';

/// 新建/编辑任务：弹出底部面板（全平台通用）
Future<void> showTaskEditSheet(
  BuildContext context,
  AppState state,
  Task? existing,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TaskEditSheet(state: state, task: existing),
  );
}

class _TaskEditSheet extends StatefulWidget {
  final AppState state;
  final Task? task;

  const _TaskEditSheet({required this.state, this.task});

  @override
  State<_TaskEditSheet> createState() => _TaskEditSheetState();
}

class _TaskEditSheetState extends State<_TaskEditSheet> {
  late final TextEditingController _title;
  late final TextEditingController _note;
  late final TextEditingController _tag;
  DateTime? _due;
  bool _dueHasTime = false;
  Priority _priority = Priority.none;
  String? _categoryId;
  TaskRepeat _repeat = TaskRepeat.none;
  final List<String> _tags = [];
  final List<Subtask> _subtasks = [];

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title = TextEditingController(text: t?.title ?? '');
    _note = TextEditingController(text: t?.note ?? '');
    _tag = TextEditingController();
    if (t != null) {
      _due = t.due;
      _dueHasTime = t.dueHasTime;
      _priority = t.priority;
      _categoryId = t.categoryId;
      _repeat = t.repeat;
      _tags.addAll(t.tags);
      _subtasks.addAll(t.subtasks);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _tag.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? now,
      firstDate: now.subtract(const Duration(days: 365 * 2)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _due = DateTime(picked.year, picked.month, picked.day,
            _due?.hour ?? 0, _due?.minute ?? 0);
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay.fromDateTime(_due ?? DateTime.now()),
    );
    if (picked != null) {
      final base = _due ?? DateTime.now();
      setState(() {
        _due =
            DateTime(base.year, base.month, base.day, picked.hour, picked.minute);
        _dueHasTime = true;
      });
    }
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    if (_isEdit) {
      final updated = widget.task!.copyWith(
        title: title,
        note: _note.text.trim(),
        due: _due,
        dueHasTime: _dueHasTime && _due != null,
        priority: _priority,
        categoryId: _categoryId,
        repeat: _repeat,
        tags: List.of(_tags),
        subtasks: List.of(_subtasks),
      );
      widget.state.updateTask(updated);
    } else {
      widget.state.addTask(Task(
        id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
        title: title,
        note: _note.text.trim(),
        due: _due,
        dueHasTime: _dueHasTime && _due != null,
        priority: _priority,
        categoryId: _categoryId,
        repeat: _repeat,
        tags: List.of(_tags),
        subtasks: List.of(_subtasks),
      ));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isEdit ? '编辑任务' : '新建任务',
                style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              autofocus: !_isEdit,
              decoration: const InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '备注',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: Icon(_due == null
                      ? Icons.event_outlined
                      : Icons.event,
                      size: 18),
                  label: Text(_due == null
                      ? '到期日期'
                      : '${_due!.year}/${_due!.month}/${_due!.day}'),
                  onPressed: _pickDate,
                ),
                ActionChip(
                  avatar: const Icon(Icons.access_time, size: 18),
                  label: Text(_dueHasTime && _due != null
                      ? '${_due!.hour}:${_due!.minute.toString().padLeft(2, '0')}'
                      : '时间'),
                  onPressed: _due == null ? null : _pickTime,
                ),
                if (_due != null)
                  ActionChip(
                    avatar: const Icon(Icons.close, size: 18),
                    label: const Text('清除'),
                    onPressed: () =>
                        setState(() {
                          _due = null;
                          _dueHasTime = false;
                        }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionLabel('优先级'),
            Wrap(
              spacing: 8,
              children: Priority.values
                  .map((p) => ChoiceChip(
                        label: Text(p.label),
                        selected: _priority == p,
                        avatar: p == Priority.none
                            ? null
                            : Icon(Icons.flag,
                                size: 16, color: p.color),
                        onSelected: (_) =>
                            setState(() => _priority = p),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            _sectionLabel('分类'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('无'),
                  selected: _categoryId == null,
                  onSelected: (_) => setState(() => _categoryId = null),
                ),
                for (final c in widget.state.categories)
                  ChoiceChip(
                    label: Text(c.name),
                    selected: _categoryId == c.id,
                    avatar:
                        Icon(Icons.lens, size: 10, color: c.color),
                    onSelected: (_) =>
                        setState(() => _categoryId = c.id),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('重复'),
            SegmentedButton<TaskRepeat>(
              segments: TaskRepeat.values
                  .map((r) => ButtonSegment(value: r, label: Text(r.label)))
                  .toList(),
              selected: {_repeat},
              onSelectionChanged: (s) =>
                  setState(() => _repeat = s.first),
            ),
            const SizedBox(height: 12),
            _sectionLabel('标签'),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final t in _tags)
                  InputChip(
                    label: Text('#$t'),
                    onDeleted: () => setState(() => _tags.remove(t)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tag,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: '输入标签，回车添加',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _addTag,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addTag(_tag.text),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _sectionLabel('子任务'),
            for (final s in _subtasks)
              Row(
                children: [
                  Checkbox(
                    value: s.done,
                    onChanged: (v) =>
                        setState(() => s.done = v ?? false),
                  ),
                  Expanded(
                    child: Text(
                      s.title,
                      style: TextStyle(
                        decoration:
                            s.done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () =>
                        setState(() => _subtasks.remove(s)),
                  ),
                ],
              ),
            _SubtaskInput(onAdd: (title) {
              setState(() {
                _subtasks.add(Subtask(
                  id: DateTime.now()
                      .microsecondsSinceEpoch
                      .toRadixString(36),
                  title: title,
                ));
              });
            }),
            const SizedBox(height: 24),
            Row(
              children: [
                if (_isEdit)
                  TextButton(
                    onPressed: () {
                      widget.state.trashTask(widget.task!.id);
                      Navigator.of(context).pop();
                    },
                    child: Text('移入回收站',
                        style: TextStyle(color: theme.colorScheme.error)),
                  ),
                const Spacer(),
                FilledButton(onPressed: _save, child: const Text('保存')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addTag(String raw) {
    final t = raw.trim().replaceAll('#', '');
    if (t.isNotEmpty && !_tags.contains(t)) {
      setState(() => _tags.add(t));
    }
    _tag.clear();
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      );
}

class _SubtaskInput extends StatefulWidget {
  final ValueChanged<String> onAdd;
  const _SubtaskInput({required this.onAdd});

  @override
  State<_SubtaskInput> createState() => _SubtaskInputState();
}

class _SubtaskInputState extends State<_SubtaskInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final t = _controller.text.trim();
    if (t.isNotEmpty) widget.onAdd(t);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              isDense: true,
              hintText: '添加子任务，回车确认',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        IconButton(icon: const Icon(Icons.add), onPressed: _submit),
      ],
    );
  }
}
