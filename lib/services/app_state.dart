import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import 'nlp_parser.dart';
import 'palette.dart';

/// 排序方式
enum SortMode { smart, due, priority, created, manual }

extension SortModeX on SortMode {
  String get label => switch (this) {
        SortMode.smart => '智能排序',
        SortMode.due => '按到期时间',
        SortMode.priority => '按优先级',
        SortMode.created => '按创建时间',
        SortMode.manual => '手动排序',
      };
}

/// 全局应用状态：任务、分类、设置、统计、撤销
class AppState extends ChangeNotifier {
  static const _key = 'taskflow_data_v1';
  static const _maxUndo = 20;

  List<Task> tasks = [];
  List<Category> categories = [];
  ThemeMode themeMode = ThemeMode.system;
  Color seedColor = const Color(0xFF4F6BFF);
  SortMode sortMode = SortMode.smart;

  final List<String> _undoStack = [];
  bool _loaded = false;

  bool get loaded => _loaded;

  // ---------- 初始化 ----------

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        tasks = (json['tasks'] as List? ?? [])
            .map((t) => Task.fromJson(t as Map<String, dynamic>))
            .toList();
        categories = (json['categories'] as List? ?? [])
            .map((c) => Category.fromJson(c as Map<String, dynamic>))
            .toList();
        themeMode =
            ThemeMode.values[json['themeMode'] as int? ?? ThemeMode.system.index];
        seedColor = Color(json['seedColor'] as int? ?? 0xFF4F6BFF);
        sortMode = SortMode.values[json['sortMode'] as int? ?? 0];
      } catch (_) {
        // 数据损坏时使用默认值
      }
    }
    if (categories.isEmpty) {
      categories = [
        Category(id: _newId(), name: '工作', color: const Color(0xFF4F6BFF)),
        Category(id: _newId(), name: '生活', color: const Color(0xFF34A853)),
        Category(id: _newId(), name: '学习', color: const Color(0xFFF29900)),
      ];
    }
    _normalizeSortIndex();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode({
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'themeMode': themeMode.index,
      'seedColor': seedColor.toARGB32(),
      'sortMode': sortMode.index,
    });
    await prefs.setString(_key, json);
  }

  void _normalizeSortIndex() {
    for (var i = 0; i < tasks.length; i++) {
      if (tasks[i].sortIndex == 0) tasks[i].sortIndex = i + 1;
    }
  }

  String _newId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36) +
      (tasks.length + categories.length).toString();

  // ---------- 撤销 ----------

  void _pushUndo() {
    final json = jsonEncode({
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
    });
    _undoStack.add(json);
    if (_undoStack.length > _maxUndo) _undoStack.removeAt(0);
  }

  /// 是否可撤销
  bool get canUndo => _undoStack.isNotEmpty;

  void undo() {
    if (_undoStack.isEmpty) return;
    final json = jsonDecode(_undoStack.removeLast()) as Map<String, dynamic>;
    tasks = (json['tasks'] as List)
        .map((t) => Task.fromJson(t as Map<String, dynamic>))
        .toList();
    categories = (json['categories'] as List)
        .map((c) => Category.fromJson(c as Map<String, dynamic>))
        .toList();
    _save();
    notifyListeners();
  }

  // ---------- 任务 CRUD ----------

  void addTask(Task task) {
    _pushUndo();
    final maxIndex =
        tasks.isEmpty ? 0 : tasks.map((t) => t.sortIndex).reduce((a, b) => a > b ? a : b);
    task.sortIndex = maxIndex + 1;
    tasks.add(task);
    _save();
    notifyListeners();
  }

  /// 自然语言快速添加，返回标题（用于提示）；若解析出未知分类会自动创建
  String addFromQuickInput(String raw) {
    final parsed = parseQuickInput(raw, categories);
    if (parsed.categoryName != null &&
        !categories.any((c) => c.name == parsed.categoryName)) {
      categories.add(Category(
        id: _newId(),
        name: parsed.categoryName!,
        color: categoryPalette[categories.length % categoryPalette.length],
      ));
    }
    Category? cat;
    if (parsed.categoryName != null) {
      cat = categories
          .where((c) => c.name == parsed.categoryName)
          .firstOrNull;
    }
    final task = Task(
      id: _newId(),
      title: parsed.title,
      due: parsed.due,
      dueHasTime: parsed.dueHasTime,
      priority: parsed.priority,
      categoryId: cat?.id,
      tags: parsed.tags,
      repeat: parsed.repeat,
    );
    addTask(task);
    return parsed.title;
  }

  void updateTask(Task task) {
    _pushUndo();
    final i = tasks.indexWhere((t) => t.id == task.id);
    if (i >= 0) tasks[i] = task;
    _save();
    notifyListeners();
  }

  /// 勾选/取消完成；重复任务完成后自动生成下一次
  void toggleDone(String id) {
    _pushUndo();
    final i = tasks.indexWhere((t) => t.id == id);
    if (i < 0) return;
    final t = tasks[i];
    if (t.status == TaskStatus.active) {
      tasks[i] = t.copyWith(
        status: TaskStatus.done,
        completedAt: DateTime.now(),
      );
      // 重复任务：生成下一次
      final nextDue = t.nextDue();
      if (nextDue != null) {
        final maxIndex = tasks
            .map((e) => e.sortIndex)
            .fold<int>(0, (a, b) => a > b ? a : b);
        tasks.add(Task(
          id: _newId(),
          title: t.title,
          note: t.note,
          due: nextDue,
          dueHasTime: t.dueHasTime,
          priority: t.priority,
          categoryId: t.categoryId,
          tags: List.of(t.tags),
          subtasks: t.subtasks
              .map((s) => Subtask(id: _newId(), title: s.title))
              .toList(),
          repeat: t.repeat,
          sortIndex: maxIndex + 1,
        ));
      }
    } else if (t.status == TaskStatus.done) {
      tasks[i] = t.copyWith(status: TaskStatus.active, completedAtClear: true);
    }
    _save();
    notifyListeners();
  }

  /// 移入回收站（软删除）
  void trashTask(String id) {
    _pushUndo();
    final i = tasks.indexWhere((t) => t.id == id);
    if (i >= 0) tasks[i] = tasks[i].copyWith(status: TaskStatus.trashed);
    _save();
    notifyListeners();
  }

  void restoreTask(String id) {
    _pushUndo();
    final i = tasks.indexWhere((t) => t.id == id);
    if (i >= 0) tasks[i] = tasks[i].copyWith(status: TaskStatus.active);
    _save();
    notifyListeners();
  }

  void archiveTask(String id) {
    _pushUndo();
    final i = tasks.indexWhere((t) => t.id == id);
    if (i >= 0) tasks[i] = tasks[i].copyWith(status: TaskStatus.archived);
    _save();
    notifyListeners();
  }

  void unarchiveTask(String id) => restoreTask(id);

  /// 彻底删除
  void deleteForever(String id) {
    _pushUndo();
    tasks.removeWhere((t) => t.id == id);
    _save();
    notifyListeners();
  }

  void emptyTrash() {
    _pushUndo();
    tasks.removeWhere((t) => t.status == TaskStatus.trashed);
    _save();
    notifyListeners();
  }

  /// 拖拽排序（onReorderItem 回调，newIndex 已调整）
  void reorderManual(int oldIndex, int newIndex) {
    _pushUndo();
    final active = tasks.where((t) => t.status == TaskStatus.active).toList()
      ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    final moved = active.removeAt(oldIndex);
    active.insert(newIndex, moved);
    for (var i = 0; i < active.length; i++) {
      final idx = tasks.indexWhere((t) => t.id == active[i].id);
      if (idx >= 0) tasks[idx] = active[i].copyWith(sortIndex: i + 1);
    }
    _save();
    notifyListeners();
  }

  // ---------- 分类 ----------

  void addCategory(String name, Color color) {
    categories.add(Category(id: _newId(), name: name, color: color));
    _save();
    notifyListeners();
  }

  void renameCategory(String id, String name) {
    final c = categories.firstWhere((c) => c.id == id);
    c.name = name;
    _save();
    notifyListeners();
  }

  void removeCategory(String id) {
    _pushUndo();
    categories.removeWhere((c) => c.id == id);
    for (var i = 0; i < tasks.length; i++) {
      if (tasks[i].categoryId == id) {
        tasks[i] = tasks[i].copyWith(categoryId: null);
      }
    }
    _save();
    notifyListeners();
  }

  Category? categoryOf(String? id) =>
      id == null ? null : categories.where((c) => c.id == id).firstOrNull;

  // ---------- 设置 ----------

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    _save();
    notifyListeners();
  }

  void setSeedColor(Color color) {
    seedColor = color;
    _save();
    notifyListeners();
  }

  void setSortMode(SortMode mode) {
    sortMode = mode;
    _save();
    notifyListeners();
  }

  void addFocusSession(String taskId) {
    final i = tasks.indexWhere((t) => t.id == taskId);
    if (i >= 0) {
      tasks[i] = tasks[i].copyWith(focusSessions: tasks[i].focusSessions + 1);
      _save();
      notifyListeners();
    }
  }

  // ---------- 统计 ----------

  List<Task> get activeTasks =>
      tasks.where((t) => t.status == TaskStatus.active).toList();

  int get doneCount => tasks.where((t) => t.status == TaskStatus.done).length;

  int get todayDoneCount {
    final now = DateTime.now();
    return tasks
        .where((t) =>
            t.status == TaskStatus.done &&
            t.completedAt != null &&
            t.completedAt!.year == now.year &&
            t.completedAt!.month == now.month &&
            t.completedAt!.day == now.day)
        .length;
  }

  int get overdueCount => tasks.where((t) => t.isOverdue).length;

  /// 最近 [days] 天每天完成数量（含今天，旧->新）
  List<int> dailyDoneCounts(int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final counts = List.filled(days, 0);
    for (final t in tasks) {
      if (t.status != TaskStatus.done || t.completedAt == null) continue;
      final c = t.completedAt!;
      final d = DateTime(c.year, c.month, c.day);
      final diff = today.difference(d).inDays;
      if (diff >= 0 && diff < days) counts[days - 1 - diff]++;
    }
    return counts;
  }

  /// 连续打卡天数（今天或昨天起往前连续每天至少完成 1 个任务）
  int get streak {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = <DateTime>{
      for (final t in tasks)
        if (t.status == TaskStatus.done && t.completedAt != null)
          DateTime(t.completedAt!.year, t.completedAt!.month,
              t.completedAt!.day),
    };
    if (days.isEmpty) return 0;
    var start = days.contains(today) ? today : today.subtract(const Duration(days: 1));
    if (!days.contains(start)) return 0;
    var count = 0;
    while (days.contains(start)) {
      count++;
      start = start.subtract(const Duration(days: 1));
    }
    return count;
  }

  /// 各分类待办数量
  Map<Category, int> activeCountByCategory() {
    final map = <Category, int>{};
    for (final c in categories) {
      map[c] = tasks
          .where((t) => t.status == TaskStatus.active && t.categoryId == c.id)
          .length;
    }
    return map;
  }

  // ---------- 导入 / 导出 ----------

  String exportJson() {
    final now = DateTime.now();
    final active = tasks.where((t) => t.status != TaskStatus.trashed).toList();
    return const JsonEncoder.withIndent('  ').convert({
      'app': 'TaskFlow',
      'version': 1,
      'exportedAt': now.toIso8601String(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'tasks': active.map((t) => t.toJson()).toList(),
    });
  }

  /// 导入：替换当前数据（不含回收站）。返回任务数。
  int importJson(String raw) {
    _pushUndo();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final cats = (json['categories'] as List? ?? [])
        .map((c) => Category.fromJson(c as Map<String, dynamic>))
        .toList();
    final ts = (json['tasks'] as List? ?? [])
        .map((t) => Task.fromJson(t as Map<String, dynamic>))
        .toList();
    if (ts.isEmpty && cats.isEmpty) throw const FormatException('无有效数据');
    categories = cats.isEmpty ? categories : cats;
    tasks = ts;
    _save();
    notifyListeners();
    return ts.length;
  }
}

