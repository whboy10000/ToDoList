import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_state.dart';
import '../services/palette.dart';

/// 设置页：外观 / 分类管理 / 数据导入导出 / 快捷键
class SettingsPage extends StatelessWidget {
  final AppState state;
  const SettingsPage({super.key, required this.state});

  Future<void> _export(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: state.exportJson()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('数据已复制到剪贴板，请粘贴保存')),
    );
  }

  Future<void> _import(BuildContext context) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入数据'),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: controller,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: '粘贴此前导出的 JSON 数据…',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('导入')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final n = state.importJson(controller.text);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已导入 $n 个任务'),
            action: SnackBarAction(label: '撤销', onPressed: state.undo),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导入失败：数据格式不正确')),
        );
      }
    }
  }

  Future<void> _addCategory(BuildContext context) async {
    final nameController = TextEditingController();
    var color = categoryPalette.first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('新建分类'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration:
                    const InputDecoration(labelText: '名称'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  for (final c in categoryPalette)
                    IconButton(
                      icon: Icon(
                        Icons.lens,
                        color: c,
                        size: color == c ? 36 : 28,
                      ),
                      onPressed: () => setState(() => color = c),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('创建')),
          ],
        ),
      ),
    );
    final name = nameController.text.trim();
    if (ok == true && name.isNotEmpty) {
      state.addCategory(name, color);
    }
  }

  Future<void> _renameCategory(BuildContext context, String id, String old) async {
    final controller = TextEditingController(text: old);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名分类'),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确定')),
        ],
      ),
    );
    final name = controller.text.trim();
    if (ok == true && name.isNotEmpty) {
      state.renameCategory(id, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('外观', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('系统')),
              ButtonSegment(value: ThemeMode.light, label: Text('浅色')),
              ButtonSegment(value: ThemeMode.dark, label: Text('深色')),
            ],
            selected: {state.themeMode},
            onSelectionChanged: (s) => state.setThemeMode(s.first),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final c in seedColorChoices)
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => state.setSeedColor(c),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: state.seedColor == c
                          ? Border.all(
                              color: theme.colorScheme.onSurface, width: 3)
                          : null,
                    ),
                    child: state.seedColor == c
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(child: Text('分类管理', style: theme.textTheme.titleMedium)),
              TextButton.icon(
                onPressed: () => _addCategory(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('新建'),
              ),
            ],
          ),
          for (final c in state.categories)
            ListTile(
              leading: Icon(Icons.lens, color: c.color),
              title: Text(c.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: '重命名',
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () =>
                        _renameCategory(context, c.id, c.name),
                  ),
                  IconButton(
                    tooltip: '删除',
                    icon: Icon(Icons.delete_outline,
                        size: 18, color: theme.colorScheme.error),
                    onPressed: () => state.removeCategory(c.id),
                  ),
                ],
              ),
            ),
          const Divider(height: 32),
          Text('数据', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('导出数据'),
            subtitle: const Text('复制 JSON 到剪贴板'),
            onTap: () => _export(context),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('导入数据'),
            subtitle: const Text('粘贴 JSON 并覆盖当前数据'),
            onTap: () => _import(context),
          ),
          const Divider(height: 32),
          Text('快捷键（桌面端）', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.keyboard_command_key),
            title: Text('Ctrl/Cmd + K'),
            subtitle: Text('打开命令面板'),
          ),
          const ListTile(
            leading: Icon(Icons.keyboard_command_key),
            title: Text('Ctrl/Cmd + N'),
            subtitle: Text('新建任务'),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('ToDoList · v0.1.0',
                style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
