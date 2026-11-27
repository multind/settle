import 'package:flutter/material.dart';
import 'package:settle_app/app/theme.dart';
import 'package:settle_app/data/providers.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/guide/page_rule_hint.dart';
import 'package:settle_app/features/task/task_list_view.dart';
import 'package:settle_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 今日页（v0.3）：`watchToday`（next_action 且 scheduled/dueDate ≤ 今日末），
/// 分区渲染——逾期（dueDate < 今日 00:00）置顶独立区块，其余为今日区。
/// 无日期 next_action 不在此页（进随时页）。
/// 公共组件 `TaskListView` 内统一排序（优先级→sortOrder→id 终局 tiebreak），
/// 逾期/今日两区经 `groupKey`（0/1）分组，区头由 `buildDateHeader` 注入。
/// 仓库约定：普通 Provider 无 watchByStatus 成员，改文件级 StreamProvider。
final _todayProjectsProvider = StreamProvider<Map<int, String>>(
  (ref) => ref
      .watch(projectRepositoryProvider)
      .watchAll()
      .map(
        (projects) => {
          for (final project in projects) project.id: project.name,
        },
      ),
);

final _todayProvider = StreamProvider<List<Task>>(
  (ref) => ref.watch(taskRepositoryProvider).watchToday(),
);

/// 今日页批量操作集（Task 2 接线 onAction 实现；本 Task 仅展示按钮）。
const _batchActions = [
  TaskListAction.complete,
  TaskListAction.delete,
  TaskListAction.setDate,
  TaskListAction.move,
];

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key, this.guide});

  final Widget? guide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tasks = ref.watch(_todayProvider);
    final projects = ref.watch(_todayProjectsProvider).asData?.value;
    return Scaffold(
      appBar: AppBar(titleSpacing: 20, title: Text(l10n.todayTitle)),
      body: Column(
        children: [
          if (guide != null) guide!,
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    MaterialLocalizations.of(context)
                        .formatFullDate(DateTime.now()),
                  ),
                ),
                if (tasks.asData case final data?)
                  Text(l10n.todayTaskCount(data.value.length)),
              ],
            ),
          ),
          Expanded(
            child: tasks.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (rows) {
                // 两区都空 → 整体空态（逾期区非空时仅显示逾期区，不出整体空态）。
                if (rows.isEmpty) {
                  return Center(
                    child: PageRuleHint(
                      icon: Icons.today,
                      title: l10n.ruleTodayTitle,
                      message: l10n.ruleTodayMessage,
                    ),
                  );
                }
                final todayStart = _todayStart();
                bool isOverdue(Task t) {
                  final d = t.dueDate;
                  if (d == null) return false;
                  return DateTime.fromMillisecondsSinceEpoch(d)
                      .isBefore(todayStart);
                }

                final overdueCount = rows.where(isOverdue).length;
                return TaskListView(
                  tasks: rows,
                  compactRows: true,
                  reorderEnabled: true,
                  selectionEnabled: true,
                  focusEnabled: true,
                  actions: _batchActions,
                  // 逾期区（键 0）置顶，今日区（键 1）其后；区头由 buildDateHeader 注入。
                  groupKey: (t) => isOverdue(t) ? 0 : 1,
                  buildDateHeader: (context, key) => key == 0
                      ? _OverdueHeader(count: overdueCount)
                      : const SizedBox.shrink(),
                  isOverdue: isOverdue,
                  subtitleBuilder: (context, t) {
                    final date = t.dueDate ?? t.scheduled;
                    final project = projects?[t.projectId];
                    if (date == null && project == null) return null;
                    final isLight =
                        Theme.of(context).brightness == Brightness.light;
                    final tokens = isLight ? AppTokens.light : AppTokens.dark;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 2,
                      children: [
                        if (date != null)
                          Text(
                            MaterialLocalizations.of(context).formatShortDate(
                              DateTime.fromMillisecondsSinceEpoch(date),
                            ),
                            style: TextStyle(
                              color: isOverdue(t)
                                  ? tokens.danger
                                  : tokens.muted,
                              fontSize: 12,
                            ),
                          ),
                        if (project != null)
                          Text(
                            project,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: tokens.muted, fontSize: 12),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 今日 00:00（以实际当前时刻取「今日」，与数据层 watchToday 的今日口径一致）。
  static DateTime _todayStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}

/// 逾期区块标题（「逾期 n 项」）。
class _OverdueHeader extends StatelessWidget {
  const _OverdueHeader({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        l10n.todayOverdue(count),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: tokens.muted,
        ),
      ),
    );
  }
}
