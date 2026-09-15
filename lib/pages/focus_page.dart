import 'dart:async';

import 'package:flutter/material.dart';

import '../services/app_state.dart';

enum _Mode { focus, shortBreak, longBreak }

extension _ModeX on _Mode {
  int get minutes => switch (this) {
        _Mode.focus => 25,
        _Mode.shortBreak => 5,
        _Mode.longBreak => 15,
      };
  String get label => switch (this) {
        _Mode.focus => '专注',
        _Mode.shortBreak => '短休息',
        _Mode.longBreak => '长休息',
      };
}

/// 番茄专注计时：为某个任务累计专注次数
class FocusPage extends StatefulWidget {
  final AppState state;
  const FocusPage({super.key, required this.state});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  _Mode _mode = _Mode.focus;
  Timer? _timer;
  int _remaining = _Mode.focus.minutes * 60;
  bool _running = false;
  String? _taskId;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectMode(_Mode m) {
    _timer?.cancel();
    setState(() {
      _mode = m;
      _running = false;
      _remaining = m.minutes * 60;
    });
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_remaining <= 1) {
      _timer?.cancel();
      setState(() {
        _running = false;
        _remaining = 0;
      });
      _onFinish();
      return;
    }
    setState(() => _remaining--);
  }

  void _onFinish() {
    if (_mode == _Mode.focus && _taskId != null) {
      widget.state.addFocusSession(_taskId!);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          _mode == _Mode.focus ? '专注完成！干得漂亮' : '休息结束，继续加油'),
    ));
    setState(() {
      _mode = _mode == _Mode.focus ? _Mode.shortBreak : _Mode.focus;
      _remaining = _mode.minutes * 60;
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remaining = _mode.minutes * 60;
    });
  }

  String get _timeText {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = widget.state.activeTasks;
    final selected =
        tasks.where((t) => t.id == _taskId).firstOrNull;
    final total = _mode.minutes * 60;
    final progress = 1 - _remaining / total;

    return Scaffold(
      appBar: AppBar(title: const Text('专注')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              SegmentedButton<_Mode>(
                segments: _Mode.values
                    .map((m) => ButtonSegment(
                        value: m,
                        label: Text('${m.label} ${m.minutes}′')))
                    .toList(),
                selected: {_mode},
                onSelectionChanged: (s) => _selectMode(s.first),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_timeText,
                            style: theme.textTheme.displayMedium),
                        Text(_mode.label,
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _toggle,
                    icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                    label: Text(_running ? '暂停' : '开始'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重置'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 320,
                child: DropdownButtonFormField<String?>(
                  initialValue: _taskId,
                  decoration: const InputDecoration(
                    labelText: '关联任务（专注完成后累计次数）',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('不关联任务')),
                    for (final t in tasks)
                      DropdownMenuItem<String?>(
                        value: t.id,
                        child: Text(t.title,
                            overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _taskId = v),
                ),
              ),
              if (selected != null && selected.focusSessions > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '「${selected.title}」已专注 ${selected.focusSessions} 个番茄',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
