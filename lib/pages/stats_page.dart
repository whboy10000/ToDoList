import 'package:flutter/material.dart';

import '../services/app_state.dart';

/// 统计页：概览数字 + 近 7 天完成柱状图 + 分类分布 + 连续打卡
class StatsPage extends StatelessWidget {
  final AppState state;
  const StatsPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counts = state.dailyDoneCounts(7);
    final streak = state.streak;
    final byCat = state.activeCountByCategory();
    final maxCat = byCat.values.fold<int>(1, (a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _StatCard(
                  label: '今日完成',
                  value: '${state.todayDoneCount}',
                  icon: Icons.today,
                  color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              _StatCard(
                  label: '待办',
                  value: '${state.activeTasks.length}',
                  icon: Icons.pending_actions,
                  color: theme.colorScheme.tertiary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                  label: '累计完成',
                  value: '${state.doneCount}',
                  icon: Icons.emoji_events_outlined,
                  color: theme.colorScheme.secondary),
              const SizedBox(width: 12),
              _StatCard(
                  label: '连续打卡',
                  value: '$streak 天',
                  icon: Icons.local_fire_department,
                  color: streak > 0 ? Colors.deepOrange : theme.hintColor),
            ],
          ),
          const SizedBox(height: 20),
          Text('近 7 天完成', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: _BarChart(counts: counts),
          ),
          const SizedBox(height: 20),
          Text('分类待办分布', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final e in byCat.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.lens, size: 10, color: e.key.color),
                  const SizedBox(width: 8),
                  SizedBox(
                      width: 72,
                      child: Text(e.key.name, overflow: TextOverflow.ellipsis)),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: e.value / maxCat,
                        minHeight: 8,
                        color: e.key.color,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                      width: 28,
                      child: Text('${e.value}',
                          textAlign: TextAlign.end,
                          style: theme.textTheme.bodySmall)),
                ],
              ),
            ),
          const SizedBox(height: 20),
          if (state.overdueCount > 0)
            Card(
              color: theme.colorScheme.errorContainer,
              child: ListTile(
                leading: Icon(Icons.warning_amber_rounded,
                    color: theme.colorScheme.onErrorContainer),
                title: Text('有 ${state.overdueCount} 个任务已过期',
                    style: TextStyle(color: theme.colorScheme.onErrorContainer)),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(label, style: theme.textTheme.bodySmall),
              ]),
              const SizedBox(height: 8),
              Text(value, style: theme.textTheme.headlineMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// 纯 CustomPainter 柱状图（零第三方依赖）
class _BarChart extends StatelessWidget {
  final List<int> counts;
  const _BarChart({required this.counts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = ['六天前', '五天前', '四天前', '三天前', '前天', '昨天', '今天'];
    final maxV = counts.fold<int>(1, (a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < counts.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${counts[i]}',
                      style: theme.textTheme.labelSmall),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: counts[i] / maxV,
                        child: Container(
                          decoration: BoxDecoration(
                            color: i == counts.length - 1
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary
                                    .withValues(alpha: 0.45),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(labels[i], style: theme.textTheme.labelSmall),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
