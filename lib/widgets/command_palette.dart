import 'package:flutter/material.dart';

import '../services/app_state.dart';

/// 命令面板（桌面端 Ctrl/Cmd+K）：搜索并执行操作或快速勾选任务
class CommandPalette extends StatelessWidget {
  final AppState state;
  final void Function(String actionId) onAction;

  const CommandPalette({
    super.key,
    required this.state,
    required this.onAction,
  });

  static const _actions = <String, (String, IconData)>{
    'new': ('新建任务', Icons.add_task),
    'toggle_theme': ('切换深浅色主题', Icons.dark_mode),
    'tasks': ('前往：任务', Icons.checklist),
    'stats': ('前往：统计', Icons.insights),
    'focus': ('前往：专注', Icons.timer),
    'settings': ('前往：设置', Icons.settings),
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: _PaletteBody(state: state, onAction: onAction),
    );
  }
}

class _PaletteBody extends StatefulWidget {
  final AppState state;
  final void Function(String actionId) onAction;

  const _PaletteBody({required this.state, required this.onAction});

  @override
  State<_PaletteBody> createState() => _PaletteBodyState();
}

class _PaletteBodyState extends State<_PaletteBody> {
  String _query = '';
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final actions = CommandPalette._actions.entries
        .where((e) => q.isEmpty || e.value.$1.toLowerCase().contains(q))
        .toList();
    final tasks = widget.state.activeTasks
        .where((t) => q.isEmpty || t.title.toLowerCase().contains(q))
        .take(6)
        .toList();

    return SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '输入命令或搜索任务…',
                prefixIcon: const Icon(Icons.terminal, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                if (actions.isEmpty && tasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('无匹配结果')),
                  ),
                for (final e in actions)
                  ListTile(
                    dense: true,
                    leading: Icon(e.value.$2, size: 20),
                    title: Text(e.value.$1),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onAction(e.key);
                    },
                  ),
                if (tasks.isNotEmpty) ...[
                  const Divider(height: 1),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text('任务（点击标记完成）',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  for (final t in tasks)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.circle_outlined, size: 18),
                      title: Text(t.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () {
                        Navigator.pop(context);
                        widget.state.toggleDone(t.id);
                      },
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
