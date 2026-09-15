import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_state.dart';
import 'focus_page.dart';
import 'settings_page.dart';
import 'stats_page.dart';
import 'task_edit_sheet.dart';
import 'tasks_page.dart';
import '../widgets/command_palette.dart';

/// 自适应主骨架：宽屏 NavigationRail，窄屏底部导航
class HomePage extends StatefulWidget {
  final AppState state;
  const HomePage({super.key, required this.state});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const _destinations = [
    (Icons.checklist, '任务'),
    (Icons.insights, '统计'),
    (Icons.timer, '专注'),
    (Icons.settings, '设置'),
  ];

  void _openPalette() {
    showDialog(
      context: context,
      builder: (_) => CommandPalette(
        state: widget.state,
        onAction: _onCommand,
      ),
    );
  }

  void _onCommand(String id) {
    switch (id) {
      case 'new':
        showTaskEditSheet(context, widget.state, null);
      case 'toggle_theme':
        final mode = widget.state.themeMode;
        widget.state.setThemeMode(
            mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
      case 'tasks':
        setState(() => _index = 0);
      case 'stats':
        setState(() => _index = 1);
      case 'focus':
        setState(() => _index = 2);
      case 'settings':
        setState(() => _index = 3);
    }
  }

  Widget _page(int i) => switch (i) {
        0 => TasksPage(state: widget.state),
        1 => StatsPage(state: widget.state),
        2 => FocusPage(state: widget.state),
        _ => SettingsPage(state: widget.state),
      };

  @override
  Widget build(BuildContext context) {
    // macOS/iOS 使用 Cmd，Windows/Linux/Android 使用 Ctrl
    final useMeta = defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.iOS;
    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyK, control: !useMeta, meta: useMeta):
            _openPalette,
        SingleActivator(LogicalKeyboardKey.keyN, control: !useMeta, meta: useMeta):
            () => showTaskEditSheet(context, widget.state, null),
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 800;
          if (wide) {
            return Scaffold(
              body: Row(
                children: [
                  NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: (i) =>
                        setState(() => _index = i),
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final d in _destinations)
                        NavigationRailDestination(
                          icon: Icon(d.$1),
                          selectedIcon: Icon(d.$1),
                          label: Text(d.$2),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: _page(_index)),
                ],
              ),
            );
          }
          return Scaffold(
            body: _page(_index),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(
                    icon: Icon(d.$1),
                    selectedIcon: Icon(d.$1),
                    label: d.$2,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
