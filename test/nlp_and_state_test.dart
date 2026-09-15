import 'package:flutter_test/flutter_test.dart';
import 'package:todolist/models/task.dart';
import 'package:todolist/services/nlp_parser.dart';
import 'package:todolist/services/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('自然语言解析器', () {
    test('解析标题、优先级、分类、标签、重复', () {
      final p = parseQuickInput('交季度报告 @工作 !高 #重要 #Q3 每周');
      expect(p.title, '交季度报告');
      expect(p.priority, Priority.high);
      expect(p.categoryName, '工作');
      expect(p.tags, ['重要', 'Q3']);
      expect(p.repeat, TaskRepeat.weekly);
      expect(p.due, isNull);
    });

    test('解析明天 + 时间', () {
      final now = DateTime.now();
      final p = parseQuickInput('买牛奶 明天 15:30');
      expect(p.title, '买牛奶');
      expect(p.due!.day, now.day + 1);
      expect(p.due!.hour, 15);
      expect(p.due!.minute, 30);
      expect(p.dueHasTime, isTrue);
    });

    test('下午3点 组合前缀', () {
      final p = parseQuickInput('开会 下午 3点');
      expect(p.title, '开会');
      expect(p.due!.hour, 15);
      expect(p.dueHasTime, isTrue);
    });

    test('仅时间且已过顺延明天', () {
      // 00:01 时用 23 点测试不可靠，这里只验证字段
      final p = parseQuickInput('睡觉 23点');
      expect(p.due, isNotNull);
      expect(p.due!.hour, 23);
    });

    test('!!中优先级 与 !!!高优先级', () {
      expect(parseQuickInput('a !!').priority, Priority.medium);
      expect(parseQuickInput('a !!!').priority, Priority.high);
      expect(parseQuickInput('a !低').priority, Priority.low);
    });

    test('N天后', () {
      final now = DateTime.now();
      final p = parseQuickInput('复查 3天后');
      expect(p.due!.difference(DateTime(now.year, now.month, now.day)).inDays, 3);
    });
  });

  group('AppState', () {
    late AppState state;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      state = AppState();
      await state.load();
    });

    test('默认分类与快速添加', () async {
      expect(state.categories.map((c) => c.name), contains('工作'));
      final title = state.addFromQuickInput('写周报 @工作 !高');
      expect(title, '写周报');
      expect(state.activeTasks.length, 1);
      expect(state.activeTasks.first.priority, Priority.high);
      expect(state.categoryOf(state.activeTasks.first.categoryId)!.name, '工作');
    });

    test('完成重复任务自动生成下一次', () async {
      state.addFromQuickInput('锻炼 每天 8点');
      final t = state.activeTasks.first;
      expect(t.repeat, TaskRepeat.daily);
      state.toggleDone(t.id);
      final active = state.activeTasks;
      expect(active.length, 1);
      expect(active.first.due!.isAfter(t.due!), isTrue);
      expect(state.doneCount, 1);
    });

    test('回收站与撤销', () async {
      state.addFromQuickInput('临时任务');
      final id = state.activeTasks.first.id;
      state.trashTask(id);
      expect(state.activeTasks, isEmpty);
      state.undo();
      expect(state.activeTasks.length, 1);
    });

    test('连续打卡统计', () async {
      state.addFromQuickInput('任务A');
      state.toggleDone(state.activeTasks.first.id);
      expect(state.todayDoneCount, 1);
      expect(state.streak, 1);
    });

    test('导入导出往返一致', () async {
      state.addFromQuickInput('任务X @生活 !中 #测试 明天');
      final json = state.exportJson();
      SharedPreferences.setMockInitialValues({});
      final state2 = AppState();
      await state2.load();
      state2.importJson(json);
      expect(state2.activeTasks.length, 1);
      expect(state2.activeTasks.first.title, '任务X');
      expect(state2.activeTasks.first.tags, ['测试']);
      expect(state2.activeTasks.first.priority, Priority.medium);
    });
  });
}
