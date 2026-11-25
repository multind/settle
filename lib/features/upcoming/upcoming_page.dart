import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/app/glass.dart';
import 'package:gtd_app/app/theme.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/task/task_edit_dialog.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';

/// 即将视图（index 2）：`watchUpcoming`（next_action 且 scheduled 或 dueDate > 今日末），
/// 按生效日期（scheduled ?? dueDate）的日分组升序时间线。
/// 日期头：近两天「明天/后天」友好文案，其余 locale 化 `M月d日 周几`（muted 小字）。
/// 组内按 优先级→sortOrder；行沿用 v0.2 样式（完成钮/编辑对话框），无 subtitle
/// （生效日期已由组头表达，避免重复）。
/// 拖拽落点由交互计划 Task 3 在此日期头上加 DragTarget，本页只渲染静态头。
/// 仓库约定：普通 Provider 无 watchByStatus 成员，改文件级 StreamProvider。
/// [now] 为可注入时钟（测试用固定时刻消除跨午夜竞态）；缺省用 `DateTime.now`
/// （与 TaskRepository 时钟注入同款口径）。
final _upcomingProvider = StreamProvider<List<Task>>(
    (ref) => ref.watch(taskRepositoryProvider).watchUpcoming());

class UpcomingPage extends ConsumerWidget {
  const UpcomingPage({super.key, this.now = DateTime.now});

  /// 可注入时钟：取「当前」时刻用于日期头「明天/后天」判定。
  final DateTime Function() now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tasks = ref.watch(_upcomingProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navUpcoming)),
      body: tasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          if (rows.isEmpty) return Center(child: Text(l10n.upcomingEmpty));
          // 今日 00:00（以注入时钟取「今日」，与数据层 watchUpcoming 口径一致）。
          final current = now();
          final today = DateTime(current.year, current.month, current.day);
          // 按生效日期（scheduled ?? dueDate）的日分组，日期升序。
          final groups = <DateTime, List<Task>>{};
          for (final t in rows) {
            groups.putIfAbsent(_effectiveDay(t), () => []).add(t);
          }
          final days = groups.keys.toList()..sort();
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: [
              for (final day in days) ...[
                _DateHeader(day: day, today: today),
                for (final t in groups[day]!..sort(_compare)) _TaskTile(task: t),
              ],
            ],
          );
        },
      ),
    );
  }

  /// 生效日期所在日（watchUpcoming OR 语义保证 scheduled/dueDate 至少其一非空）。
  static DateTime _effectiveDay(Task t) {
    assert(t.scheduled != null || t.dueDate != null,
        'watchUpcoming 返回行必有 scheduled 或 dueDate');
    final eff = DateTime.fromMillisecondsSinceEpoch(t.scheduled ?? t.dueDate!);
    return DateTime(eff.year, eff.month, eff.day);
  }

  /// 组内排序：优先级 → sortOrder（同一天分组内无需再按日期比较）。
  static int _compare(Task a, Task b) {
    final pa = _priorityIndex(a.priority);
    final pb = _priorityIndex(b.priority);
    if (pa != pb) return pa.compareTo(pb);
    return a.sortOrder.compareTo(b.sortOrder);
  }

  static int _priorityIndex(String? p) => switch (p) {
        'high' => 0,
        'medium' => 1,
        'low' => 2,
        _ => 3,
      };
}

/// 日期头（静态）：明天/后天用友好文案，其余 `M月d日 周几`；muted 小字。
/// 拖拽落点（DragTarget）由交互计划 Task 3 加在此头上。
/// [today] 为「今日 00:00」，由页面注入时钟计算后传入（本 widget 不直接取时钟）。
class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.day, required this.today});
  final DateTime day;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    return Padding(
      key: Key('upcoming_date_header_${day.year}_${day.month}_${day.day}'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        _headerText(l10n),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: tokens.muted,
        ),
      ),
    );
  }

  String _headerText(AppLocalizations l10n) {
    final diff = day.difference(today).inDays;
    if (diff == 1) return l10n.upcomingTomorrow;
    if (diff == 2) return l10n.upcomingDayAfter;
    return l10n.upcomingDateHeader(
        day.month, day.day, _weekdayName(l10n, day.weekday));
  }

  /// 周几名（locale 化，1=周一 … 7=周日）。
  static String _weekdayName(AppLocalizations l10n, int weekday) =>
      switch (weekday) {
        DateTime.monday => l10n.weekdayMon,
        DateTime.tuesday => l10n.weekdayTue,
        DateTime.wednesday => l10n.weekdayWed,
        DateTime.thursday => l10n.weekdayThu,
        DateTime.friday => l10n.weekdayFri,
        DateTime.saturday => l10n.weekdaySat,
        _ => l10n.weekdaySun,
      };
}

/// 即将行（v0.2 样式，同随时页 _TaskTile）：完成钮 / 点击编辑 / GlassContainer 圆角零阴影。
class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    final row = ListTile(
      key: Key('task_tile_${task.id}'),
      title: Text(task.title),
      leading: IconButton(
        key: Key('task_done_${task.id}'),
        tooltip: l10n.markDone,
        onPressed: () => ref.read(taskRepositoryProvider).complete(task.id),
        icon: const GlassCheckbox(value: false, onChanged: null),
      ),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => TaskEditDialog(task: task),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: GlassContainer(
        color: tokens.cardSolid,
        blur: 5,
        saturate: 1.0,
        borderColor: tokens.stroke,
        borderRadius: BorderRadius.circular(AppTokens.radiusRow),
        shadow: tokens.shadowSm,
        child: row,
      ),
    );
  }
}
