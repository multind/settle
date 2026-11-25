import 'package:flutter/material.dart';
import 'package:gtd_app/app/glass.dart';
import 'package:gtd_app/app/theme.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/task/task_edit_dialog.dart';

/// 今日页（v0.3）：`watchToday`（next_action 且 scheduled/dueDate ≤ 今日末），
/// 分区渲染——逾期（dueDate < 今日 00:00）置顶独立区块，其余为今日区。
/// 无日期 next_action 不在此页（进随时页）。
/// 仓库约定：普通 Provider 无 watchByStatus 成员，改文件级 StreamProvider。
final _todayProvider = StreamProvider<List<Task>>(
    (ref) => ref.watch(taskRepositoryProvider).watchToday());

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tasks = ref.watch(_todayProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.todayTitle)),
      body: tasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          // 两区都空 → 整体空态（逾期区非空时仅显示逾期区，不出整体空态）。
          if (rows.isEmpty) return Center(child: Text(l10n.todayEmpty));
          final todayStart = _todayStart();
          bool isOverdue(Task t) {
            final d = t.dueDate;
            if (d == null) return false;
            return DateTime.fromMillisecondsSinceEpoch(d).isBefore(todayStart);
          }

          final overdue = rows.where(isOverdue).toList()..sort(_compare);
          final today = rows.where((t) => !isOverdue(t)).toList()..sort(_compare);
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: [
              if (overdue.isNotEmpty) ...[
                _OverdueHeader(count: overdue.length),
                ...overdue.map((t) => _TaskTile(task: t, overdue: true)),
              ],
              ...today.map((t) => _TaskTile(task: t)),
            ],
          );
        },
      ),
    );
  }

  /// 今日 00:00（以实际当前时刻取「今日」，与数据层 watchToday 的今日口径一致）。
  static DateTime _todayStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// 优先级 → 生效日期（scheduled ?? dueDate）升序。
  static int _compare(Task a, Task b) {
    final pa = _priorityIndex(a.priority);
    final pb = _priorityIndex(b.priority);
    if (pa != pb) return pa.compareTo(pb);
    final da = a.scheduled ?? a.dueDate ?? 1 << 62;
    final db2 = b.scheduled ?? b.dueDate ?? 1 << 62;
    return da.compareTo(db2);
  }

  static int _priorityIndex(String? p) => switch (p) {
        'high' => 0,
        'medium' => 1,
        'low' => 2,
        _ => 3,
      };
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

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task, this.overdue = false});
  final Task task;
  final bool overdue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    final row = ListTile(
      key: Key('task_tile_${task.id}'),
      title: Text(task.title),
      subtitle: task.dueDate == null
          ? null
          : Text(
              DateTime.fromMillisecondsSinceEpoch(task.dueDate!)
                  .toString()
                  .substring(0, 10),
              style: TextStyle(
                color: overdue ? tokens.danger : tokens.muted,
                fontSize: 12,
              ),
            ),
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
    Widget tile = GlassContainer(
      color: tokens.cardSolid,
      blur: 5,
      saturate: 1.0,
      borderColor: tokens.stroke,
      borderRadius: BorderRadius.circular(AppTokens.radiusRow),
      shadow: tokens.shadowSm,
      child: row,
    );
    // 逾期行：左侧 1px danger 色条（描边在圆角容器外，视觉独立于 hairline）。
    if (overdue) {
      tile = Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: tokens.danger, width: 1)),
          borderRadius: BorderRadius.circular(AppTokens.radiusRow),
        ),
        child: tile,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: tile,
    );
  }
}
