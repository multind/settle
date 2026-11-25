import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/app/theme.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/task/task_list_view.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';

/// 即将视图（index 2）：`watchUpcoming`（next_action 且 scheduled 或 dueDate > 今日末），
/// 按生效日期（scheduled ?? dueDate）的日分组升序时间线。
/// 公共组件 `TaskListView` 内统一排序 + 分组（`groupKey` = 生效日 DateTime），
/// 组头由 `buildDateHeader` 注入（日期头 = 拖到日期的 DragTarget 落点，Task 3）。
/// 行沿用 v0.2 样式（完成钮/编辑对话框），无 subtitle（生效日期已由组头表达）。
/// 仓库约定：普通 Provider 无 watchByStatus 成员，改文件级 StreamProvider。
/// [now] 为可注入时钟（测试用固定时刻消除跨午夜竞态）；缺省用 `DateTime.now`
/// （与 TaskRepository 时钟注入同款口径）。
final _upcomingProvider = StreamProvider<List<Task>>(
    (ref) => ref.watch(taskRepositoryProvider).watchUpcoming());

/// 即将页批量操作集（Task 2 接线 onAction 实现；本 Task 仅展示按钮）。
const _batchActions = [
  TaskListAction.complete,
  TaskListAction.delete,
  TaskListAction.setDate,
  TaskListAction.move,
];

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
          return TaskListView(
            tasks: rows,
            reorderEnabled: true,
            selectionEnabled: true,
            focusEnabled: true,
            actions: _batchActions,
            dragToDateEnabled: true,
            groupKey: _effectiveDay,
            buildDateHeader: (context, key) {
              final day = key as DateTime;
              return _DateHeader(
                day: day,
                today: today,
                tasks: rows,
                onDrop: (taskId) {
                  // invariant：落点日期头只渲染未来日（watchUpcoming 要求
                  // scheduled/dueDate > 今日末），故 day > today 恒成立，下方
                  // isBefore 分支**不可达**——语义兜底防后人误删：若未来渲染出
                  // 「≤ 今日」头部，按 spec §4 落入今日（setScheduled(today)）。
                  final target = day.isBefore(today) ? today : day;
                  ref.read(taskRepositoryProvider).setScheduled(taskId, target);
                },
              );
            },
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
}

/// 日期头 = 拖到日期的落点（DragTarget<int>，Task 3）：悬停时描边 primary；
/// `onWillAccept` 拒绝同日期（任务当前所在组），`onAccept` 走页面 onDrop 写 scheduled
/// （目标日 ≤ 今日按「落今日」语义处理，见页面注释）。
/// 明天/后天用友好文案，其余 `M月d日 周几`；muted 小字。
/// [tasks] 为页面当前行（供 onWillAccept 查任务当前生效日，同日期不接受）。
class _DateHeader extends StatelessWidget {
  const _DateHeader({
    required this.day,
    required this.today,
    required this.tasks,
    required this.onDrop,
  });

  /// 该组头的生效日（已归一化到当日 00:00）。
  final DateTime day;

  /// 「今日 00:00」，由页面注入时钟计算后传入（本 widget 不直接取时钟）。
  final DateTime today;

  /// 页面当前行快照：查任务当前生效日，判断落点是否同日期。
  final List<Task> tasks;

  /// 接受落点的回调（页面实现：setScheduled + 「落今日」兜底）。
  final void Function(int taskId) onDrop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    // 拖拽中逐次悬停查表 O(1)：快照行 id → Task。
    final byId = <int, Task>{for (final t in tasks) t.id: t};
    return DragTarget<int>(
      key: Key('upcoming_date_drop_${day.year}_${day.month}_${day.day}'),
      onWillAcceptWithDetails: (details) {
        final task = byId[details.data];
        // 拖拽中 stream 回填可能使快照暂时查不到被拖行：**放行**（setScheduled
        // 按 id 幂等，不存在该 id 时为空更新），避免合法 drop 被陈旧快照拒绝。
        if (task == null) return true;
        // 不合法目标：拖回任务当前所在组（同日期）不接受；
        // 目标日 ≤ 今日的头部本视图不渲染，若出现则由 onDrop 落今日兜底。
        return UpcomingPage._effectiveDay(task) != day;
      },
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidateData, rejectedData) {
        final isCandidate = candidateData.isNotEmpty;
        // 恒定 2px 描边（未悬停透明）：悬停高亮不引起布局位移。
        return Padding(
          key: Key('upcoming_date_header_${day.year}_${day.month}_${day.day}'),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
          child: DecoratedBox(
            key: Key(
                'upcoming_date_highlight_${day.year}_${day.month}_${day.day}'),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isCandidate ? tokens.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
              child: Text(
                _headerText(l10n),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tokens.muted,
                ),
              ),
            ),
          ),
        );
      },
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
