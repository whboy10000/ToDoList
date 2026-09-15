import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/app_state.dart';
import '../widgets/task_tile.dart';

enum _View { active, done, all }

/// 任务列表主页：搜索/筛选/排序/分组/快速添加/拖拽排序
class TasksPage extends StatefulWidget {
  final AppState state;
  const TasksPage({super.key, required this.state});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  _View _view = _View.active;
  String? _categoryFilter;
  String _search = '';
  bool _searchOn = false;
  final _quickController = TextEditingController();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _quickController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _quickAdd() {
    final raw = _quickController.text.trim();
    if (raw.isEmpty) return;
    final title = widget.state.addFromQuickInput(raw);
    _quickController.clear();
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('已添加「$title」'),
      duration: const Duration(seconds: 2),
    ));
  }

  List<Task> _filtered() {
    Iterable<Task> list = widget.state.tasks;
    switch (_view) {
      case _View.active:
        list = list.where((t) => t.status == TaskStatus.active);
      case _View.done:
        list = list.where((t) => t.status == TaskStatus.done);
      case _View.all:
        list = list.where(
            (t) => t.status == TaskStatus.active || t.status == TaskStatus.done);
    }
    if (_categoryFilter != null) {
      list = list.where((t) => t.categoryId == _categoryFilter);
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((t) =>
          t.title.toLowerCase().contains(q) ||
          t.note.toLowerCase().contains(q) ||
          t.tags.any((g) => g.toLowerCase().contains(q)));
    }
    final result = list.toList();
    switch (widget.state.sortMode) {
      case SortMode.smart:
        int rank(Task t) {
          if (t.isDone) return 3;
          if (t.isOverdue) return 0;
          if (t.isDueToday) return 1;
          return 2;
        }

        result.sort((a, b) {
          final r = rank(a).compareTo(rank(b));
          if (r != 0) return r;
          final ad = a.due, bd = b.due;
          if (ad == null || bd == null) {
            if (ad == null && bd == null) {
              return b.priority.index.compareTo(a.priority.index);
            }
            return ad == null ? 1 : -1;
          }
          final c = ad.compareTo(bd);
          if (c != 0) return c;
          return b.priority.index.compareTo(a.priority.index);
        });
      case SortMode.due:
        result.sort((a, b) {
          final ad = a.due, bd = b.due;
          if (ad == null && bd == null) return 0;
          if (ad == null) return 1;
          if (bd == null) return -1;
          return ad.compareTo(bd);
        });
      case SortMode.priority:
        result.sort((a, b) => b.priority.index.compareTo(a.priority.index));
      case SortMode.created:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortMode.manual:
        result.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    }
    return result;
  }

  /// 按到期时间分桶（仅对未完成任务）
  Map<String, List<Task>> _groupByDue(List<Task> tasks) {
    final groups = <String, List<Task>>{};
    void add(String key, Task t) =>
        (groups.putIfAbsent(key, () => [])).add(t);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final t in tasks.where((t) => !t.isDone)) {
      final d = t.due;
      if (d == null) {
        add('无日期', t);
        continue;
      }
      final dd = DateTime(d.year, d.month, d.day);
      final diff = dd.difference(today).inDays;
      if (diff < 0) {
        add('已过期', t);
      } else if (diff == 0) {
        add('今天', t);
      } else if (diff == 1) {
        add('明天', t);
      } else if (diff <= 7 - now.weekday) {
        add('本周', t);
      } else {
        add('以后', t);
      }
    }
    const order = ['已过期', '今天', '明天', '本周', '以后', '无日期'];
    return {
      for (final k in order)
        if (groups.containsKey(k)) k: groups[k]!,
    };
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in SortMode.values)
              ListTile(
                leading: Icon(
                  widget.state.sortMode == m
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: Text(m.label),
                onTap: () {
                  widget.state.setSortMode(m);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showQuickHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('快速输入语法'),
        content: const Text(
          '输入任务标题时可混用以下标记（用空格分隔）：\n\n'
          '· 日期：今天 / 明天 / 后天 / 大后天 / 3天后 / 周三 / 下周一 / 9月20日\n'
          '· 时间：15:30 / 3点 / 3点半 / 下午3点 / 晚上8点半 / 中午12点\n'
          '· 优先级：!高 !中 !低（或 !!! !!）\n'
          '· 分类：@工作（不存在会自动创建）\n'
          '· 标签：#健身（可多个）\n'
          '· 重复：每天 每周 每月\n\n'
          '示例：明天 下午3点 交季度报告 @工作 !高 #重要 每周',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final tasks = _filtered();
    final grouping =
        state.sortMode != SortMode.manual && _view != _View.done;

    return Scaffold(
      appBar: AppBar(
        title: const Text('任务'),
        actions: [
          IconButton(
            tooltip: '搜索',
            icon: Icon(_searchOn ? Icons.search_off : Icons.search),
            onPressed: () {
              setState(() {
                _searchOn = !_searchOn;
                if (!_searchOn) {
                  _search = '';
                  _searchController.clear();
                }
              });
            },
          ),
          IconButton(
            tooltip: state.sortMode.label,
            icon: const Icon(Icons.sort),
            onPressed: _showSortMenu,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'archive') {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => _StatusListPage(
                      state: state, status: TaskStatus.archived),
                ));
              } else if (v == 'trash') {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => _StatusListPage(
                      state: state, status: TaskStatus.trashed),
                ));
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'archive', child: Text('已归档')),
              PopupMenuItem(value: 'trash', child: Text('回收站')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchOn)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  hintText: '搜索标题、备注、标签',
                  border: const OutlineInputBorder(),
                  suffixIcon: _search.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                        ),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<_View>(
              segments: const [
                ButtonSegment(value: _View.active, label: Text('待办')),
                ButtonSegment(value: _View.done, label: Text('已完成')),
                ButtonSegment(value: _View.all, label: Text('全部')),
              ],
              selected: {_view},
              onSelectionChanged: (s) => setState(() => _view = s.first),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                FilterChip(
                  label: const Text('全部分类'),
                  selected: _categoryFilter == null,
                  onSelected: (_) => setState(() => _categoryFilter = null),
                ),
                const SizedBox(width: 8),
                for (final c in state.categories) ...[
                  FilterChip(
                    label: Text(c.name),
                    selected: _categoryFilter == c.id,
                    onSelected: (_) =>
                        setState(() => _categoryFilter = c.id),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: state.sortMode == SortMode.manual && _view != _View.done
                ? _buildReorderable(tasks)
                : _buildList(tasks, grouping),
          ),
        ],
      ),
      bottomNavigationBar: _QuickAddBar(
        controller: _quickController,
        onSubmit: _quickAdd,
        onHelp: _showQuickHelp,
      ),
    );
  }

  Widget _buildList(List<Task> tasks, bool grouping) {
    final state = widget.state;
    if (tasks.isEmpty) return _empty();

    final children = <Widget>[];
    if (grouping && state.sortMode != SortMode.priority) {
      final groups = _groupByDue(tasks);
      final done = tasks.where((t) => t.isDone).toList();
      groups.forEach((key, list) {
        children.add(_header('$key · ${list.length}',
            color: key == '已过期' ? Theme.of(context).colorScheme.error : null));
        children.addAll(list
            .map((t) => TaskTile(state: state, task: t, showMenu: !t.isDone)));
      });
      if (done.isNotEmpty && _view != _View.active) {
        children.add(_header('已完成 · ${done.length}'));
        children.addAll(done.map((t) => TaskTile(state: state, task: t)));
      }
    } else {
      children.addAll(tasks.map((t) => TaskTile(state: state, task: t)));
    }
    return ListView(children: children);
  }

  Widget _buildReorderable(List<Task> tasks) {
    final state = widget.state;
    final active = tasks.where((t) => !t.isDone).toList();
    if (tasks.isEmpty) return _empty();
    return ListView(
      children: [
        _header('长按拖动调整顺序 · ${active.length} 项'),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: active.length,
          onReorderItem: state.reorderManual,
          itemBuilder: (ctx, i) => ReorderableDragStartListener(
            key: ValueKey(active[i].id),
            index: i,
            child: TaskTile(state: state, task: active[i]),
          ),
        ),
        ...tasks.where((t) => t.isDone).map(
              (t) => TaskTile(state: state, task: t, showMenu: false),
            ),
      ],
    );
  }

  Widget _header(String text, {Color? color}) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color ?? Theme.of(context).hintColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      );

  Widget _empty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text('这里空空如也'),
            const SizedBox(height: 4),
            Text('在下方输入框快速添加任务吧',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
}

class _QuickAddBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final VoidCallback onHelp;

  const _QuickAddBar({
    required this.controller,
    required this.onSubmit,
    required this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onSubmit(),
                decoration: InputDecoration(
                  hintText: '快速添加：明天 下午3点 写周报 @工作 !高',
                  prefixIcon: const Icon(Icons.bolt, size: 20),
                  isDense: true,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: '添加',
              icon: const Icon(Icons.add),
              onPressed: onSubmit,
            ),
            IconButton(
              tooltip: '语法帮助',
              icon: const Icon(Icons.help_outline, size: 20),
              onPressed: onHelp,
            ),
          ],
        ),
      ),
    );
  }
}

/// 归档 / 回收站列表页
class _StatusListPage extends StatelessWidget {
  final AppState state;
  final TaskStatus status;

  const _StatusListPage({required this.state, required this.status});

  bool get _isTrash => status == TaskStatus.trashed;

  @override
  Widget build(BuildContext context) {
    final tasks = state.tasks.where((t) => t.status == status).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Scaffold(
      appBar: AppBar(
        title: Text(_isTrash ? '回收站' : '已归档'),
        actions: [
          if (_isTrash && tasks.isNotEmpty)
            IconButton(
              tooltip: '清空回收站',
              icon: const Icon(Icons.delete_forever),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('清空回收站？'),
                    content: const Text('其中所有任务将被彻底删除，此操作仍可通过撤销恢复。'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('取消')),
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('清空')),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  state.emptyTrash();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('回收站已清空'),
                    action: SnackBarAction(label: '撤销', onPressed: state.undo),
                  ));
                }
              },
            ),
        ],
      ),
      body: tasks.isEmpty
          ? const Center(child: Text('暂无内容'))
          : ListView(
              children: [
                for (final t in tasks)
                  ListTile(
                    title: Text(t.title),
                    subtitle: t.due == null
                        ? null
                        : Text('到期：${t.due!.year}/${t.due!.month}/${t.due!.day}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: _isTrash ? '恢复' : '取消归档',
                          icon: Icon(_isTrash
                              ? Icons.restore_from_trash
                              : Icons.unarchive),
                          onPressed: () {
                            state.restoreTask(t.id);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: const Text('已恢复'),
                              action:
                                  SnackBarAction(label: '撤销', onPressed: state.undo),
                            ));
                          },
                        ),
                        if (_isTrash)
                          IconButton(
                            tooltip: '彻底删除',
                            icon: Icon(Icons.delete,
                                color: Theme.of(context).colorScheme.error),
                            onPressed: () => state.deleteForever(t.id),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
