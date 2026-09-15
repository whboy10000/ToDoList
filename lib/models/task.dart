import 'package:flutter/material.dart';

/// 优先级
enum Priority { none, low, medium, high }

extension PriorityX on Priority {
  String get label => switch (this) {
        Priority.none => '无',
        Priority.low => '低',
        Priority.medium => '中',
        Priority.high => '高',
      };

  Color get color => switch (this) {
        Priority.none => Colors.grey,
        Priority.low => Colors.green,
        Priority.medium => Colors.orange,
        Priority.high => Colors.red,
      };
}

/// 重复规则
enum TaskRepeat { none, daily, weekly, monthly }

extension TaskRepeatX on TaskRepeat {
  String get label => switch (this) {
        TaskRepeat.none => '不重复',
        TaskRepeat.daily => '每天',
        TaskRepeat.weekly => '每周',
        TaskRepeat.monthly => '每月',
      };
}

/// 任务状态
enum TaskStatus { active, done, archived, trashed }

/// 子任务
class Subtask {
  String id;
  String title;
  bool done;

  Subtask({required this.id, required this.title, this.done = false});

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
        id: json['id'] as String,
        title: json['title'] as String,
        done: json['done'] as bool? ?? false,
      );
}

/// 任务
class Task {
  String id;
  String title;
  String note;
  DateTime? due;
  bool dueHasTime;
  Priority priority;
  String? categoryId;
  List<String> tags;
  List<Subtask> subtasks;
  TaskRepeat repeat;
  TaskStatus status;
  DateTime createdAt;
  DateTime? completedAt;
  int focusSessions; // 番茄钟专注次数
  int sortIndex;

  Task({
    required this.id,
    required this.title,
    this.note = '',
    this.due,
    this.dueHasTime = false,
    this.priority = Priority.none,
    this.categoryId,
    List<String>? tags,
    List<Subtask>? subtasks,
    this.repeat = TaskRepeat.none,
    this.status = TaskStatus.active,
    DateTime? createdAt,
    this.completedAt,
    this.focusSessions = 0,
    this.sortIndex = 0,
  })  : tags = tags ?? [],
        subtasks = subtasks ?? [],
        createdAt = createdAt ?? DateTime.now();

  bool get isDone => status == TaskStatus.done;

  /// 未完成且已过期（纯日期任务按天比较，含时间任务按时刻比较）
  bool get isOverdue {
    if (due == null || status != TaskStatus.active) return false;
    final now = DateTime.now();
    if (!dueHasTime) {
      final today = DateTime(now.year, now.month, now.day);
      final d = DateTime(due!.year, due!.month, due!.day);
      return d.isBefore(today);
    }
    return due!.isBefore(now);
  }

  /// 是否今天到期
  bool get isDueToday {
    if (due == null) return false;
    final now = DateTime.now();
    return due!.year == now.year &&
        due!.month == now.month &&
        due!.day == now.day;
  }

  int get subtasksDone => subtasks.where((s) => s.done).length;

  Task copyWith({
    String? title,
    String? note,
    Object? due = _unset,
    bool? dueHasTime,
    Priority? priority,
    Object? categoryId = _unset,
    List<String>? tags,
    List<Subtask>? subtasks,
    TaskRepeat? repeat,
    TaskStatus? status,
    DateTime? completedAt,
    Object? completedAtClear = _unset,
    int? focusSessions,
    int? sortIndex,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        note: note ?? this.note,
        due: due == _unset ? this.due : due as DateTime?,
        dueHasTime: dueHasTime ?? this.dueHasTime,
        priority: priority ?? this.priority,
        categoryId:
            categoryId == _unset ? this.categoryId : categoryId as String?,
        tags: tags ?? this.tags,
        subtasks: subtasks ?? this.subtasks,
        repeat: repeat ?? this.repeat,
        status: status ?? this.status,
        createdAt: createdAt,
        completedAt: completedAtClear != _unset
            ? null
            : (completedAt ?? this.completedAt),
        focusSessions: focusSessions ?? this.focusSessions,
        sortIndex: sortIndex ?? this.sortIndex,
      );

  static const _unset = Object();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'due': due?.toIso8601String(),
        'dueHasTime': dueHasTime,
        'priority': priority.index,
        'categoryId': categoryId,
        'tags': tags,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'repeat': repeat.index,
        'status': status.index,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'focusSessions': focusSessions,
        'sortIndex': sortIndex,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        note: json['note'] as String? ?? '',
        due: (json['due'] as String?) == null
            ? null
            : DateTime.parse(json['due'] as String),
        dueHasTime: json['dueHasTime'] as bool? ?? false,
        priority: Priority.values[json['priority'] as int? ?? 0],
        categoryId: json['categoryId'] as String?,
        tags: (json['tags'] as List?)?.cast<String>() ?? [],
        subtasks: (json['subtasks'] as List? ?? [])
            .map((s) => Subtask.fromJson(s as Map<String, dynamic>))
            .toList(),
        repeat: TaskRepeat.values[json['repeat'] as int? ?? 0],
        status: TaskStatus.values[json['status'] as int? ?? 0],
        createdAt: (json['createdAt'] as String?) == null
            ? DateTime.now()
            : DateTime.parse(json['createdAt'] as String),
        completedAt: (json['completedAt'] as String?) == null
            ? null
            : DateTime.parse(json['completedAt'] as String),
        focusSessions: json['focusSessions'] as int? ?? 0,
        sortIndex: json['sortIndex'] as int? ?? 0,
      );

  /// 根据重复规则计算下一次到期时间
  DateTime? nextDue() {
    if (due == null) return null;
    switch (repeat) {
      case TaskRepeat.none:
        return null;
      case TaskRepeat.daily:
        return due!.add(const Duration(days: 1));
      case TaskRepeat.weekly:
        return due!.add(const Duration(days: 7));
      case TaskRepeat.monthly:
        final m = DateTime(due!.year, due!.month + 1, due!.day);
        return m;
    }
  }
}

/// 分类
class Category {
  String id;
  String name;
  Color color;

  Category({required this.id, required this.name, required this.color});

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'color': color.toARGB32()};

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        color: Color(json['color'] as int),
      );
}
