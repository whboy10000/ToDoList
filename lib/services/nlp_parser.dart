import '../models/task.dart';

/// 自然语言快速输入解析结果
class ParsedInput {
  final String title;
  final DateTime? due;
  final bool dueHasTime;
  final Priority priority;
  final String? categoryName;
  final List<String> tags;
  final TaskRepeat repeat;

  ParsedInput({
    required this.title,
    required this.due,
    required this.dueHasTime,
    required this.priority,
    required this.categoryName,
    required this.tags,
    required this.repeat,
  });
}

/// 解析快速输入，支持：
/// - 日期：今天/明天/后天/大后天/3天后/周一~周日/下周三/9月20日
/// - 时间：15:30 / 3点 / 3点半 / 3点15分 / 下午3点 / 晚上8点半 / 中午12点（"下午 3点" 分开写也支持）
/// - 优先级：!高 !中 !低（或 !!! !!）
/// - 分类：@工作
/// - 标签：#健身
/// - 重复：每天 每周 每月
ParsedInput parseQuickInput(String raw,
    [List<Category> knownCategories = const []]) {
  final tokens =
      raw.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  const dateWords = ['今天', '明天', '后天', '大后天'];
  const weekNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  const weekAlt = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
  const timePrefixes = ['早上', '上午', '中午', '下午', '晚上'];

  DateTime? date;
  int? hour;
  int minute = 0;
  String? pendingPrefix;
  final titleTokens = <String>[];

  void flushPrefix() {
    if (pendingPrefix != null) {
      titleTokens.add(pendingPrefix!);
      pendingPrefix = null;
    }
  }

  for (final token in tokens) {
    // 先尝试把 pending 前缀与当前 token 组合成时间（如 "下午" + "3点"）
    if (pendingPrefix != null) {
      final t = _parseHourToken(token, pendingPrefix);
      if (t != null) {
        hour = t.$1;
        minute = t.$2;
        pendingPrefix = null;
        continue;
      }
      flushPrefix();
    }

    // 时间前缀单独成 token（如 "下午 3点"）
    if (timePrefixes.contains(token)) {
      pendingPrefix = token;
      continue;
    }

    var matched = true;

    if (dateWords.contains(token)) {
      date = today.add(Duration(days: dateWords.indexOf(token)));
    } else if (RegExp(r'^\d+天后$').hasMatch(token)) {
      date = today.add(Duration(days: int.parse(token.replaceAll('天后', ''))));
    } else if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(token)) {
      final p = token.split(':');
      final h = int.parse(p[0]);
      final m2 = int.parse(p[1]);
      if (h > 23 || m2 > 59) {
        matched = false;
      } else {
        hour = h;
        minute = m2;
      }
    } else if (RegExp(r'^\d{1,2}点(半|\d{1,2}分?)?$').hasMatch(token)) {
      final t = _parseHourToken(token, null);
      if (t != null) {
        hour = t.$1;
        minute = t.$2;
      } else {
        matched = false;
      }
    } else if (weekNames.contains(token) || weekAlt.contains(token)) {
      final idx = weekNames.contains(token)
          ? weekNames.indexOf(token)
          : weekAlt.indexOf(token);
      final diff = (idx + 1 - now.weekday) % 7;
      date = today.add(Duration(days: diff == 0 ? 7 : diff));
    } else if (token.length > 2 && token.startsWith('下周')) {
      final w = token.substring(2);
      final idx = weekNames.contains(w)
          ? weekNames.indexOf(w)
          : weekAlt.indexOf(w);
      if (idx >= 0) {
        final diff = (idx + 1 - now.weekday) % 7;
        date = today.add(Duration(days: diff + 7));
      } else {
        matched = false;
      }
    } else if (RegExp(r'^\d{1,2}月\d{1,2}日$').hasMatch(token)) {
      final m = RegExp(r'^(\d{1,2})月(\d{1,2})日$').firstMatch(token)!;
      var d = DateTime(now.year, int.parse(m.group(1)!), int.parse(m.group(2)!));
      if (d.isBefore(today)) d = DateTime(now.year + 1, d.month, d.day);
      date = d;
    } else {
      matched = false;
    }

    if (matched) {
      continue;
    }
    titleTokens.add(token);
  }
  flushPrefix();

  // 优先级 / 重复 / 分类 / 标签
  var priority = Priority.none;
  var repeat = TaskRepeat.none;
  String? categoryName;
  final tags = <String>[];
  final title = <String>[];
  for (final tk in titleTokens) {
    if (tk == '!高' || tk == '!!!') {
      priority = Priority.high;
    } else if (tk == '!中' || tk == '!!') {
      priority = Priority.medium;
    } else if (tk == '!低') {
      priority = Priority.low;
    } else if (tk == '每天' || tk == '每日') {
      repeat = TaskRepeat.daily;
    } else if (tk == '每周') {
      repeat = TaskRepeat.weekly;
    } else if (tk == '每月') {
      repeat = TaskRepeat.monthly;
    } else if (tk.startsWith('@') && tk.length > 1) {
      categoryName = tk.substring(1);
    } else if (tk.startsWith('#') && tk.length > 1) {
      tags.add(tk.substring(1));
    } else {
      title.add(tk);
    }
  }

  // 组合日期与时间
  DateTime? due;
  final hasTime = hour != null;
  if (hasTime) {
    final base = date ?? today;
    due = DateTime(base.year, base.month, base.day, hour, minute);
    if (date == null && due.isBefore(now)) {
      due = due.add(const Duration(days: 1)); // 只有时间且已过，顺延到明天
    }
  } else {
    due = date;
  }

  return ParsedInput(
    title: title.join(' ').trim(),
    due: due,
    dueHasTime: hasTime,
    priority: priority,
    categoryName: categoryName,
    tags: tags,
    repeat: repeat,
  );
}

/// 解析 "3点" "3点半" "3点15分" "3点15"，可带前缀（下午/晚上/中午/上午/早上）
(int, int)? _parseHourToken(String token, String? prefix) {
  final m = RegExp(r'^(\d{1,2})点(半|(\d{1,2})分?)?$').firstMatch(token);
  if (m == null) return null;
  var h = int.parse(m.group(1)!);
  final min = m.group(2) == '半' ? 30 : int.tryParse(m.group(3) ?? '') ?? 0;
  switch (prefix) {
    case '下午' || '晚上':
      if (h < 12) h += 12;
    case '中午':
      if (h < 11) h += 12;
  }
  if (h > 23 || min > 59) return null;
  return (h, min);
}
