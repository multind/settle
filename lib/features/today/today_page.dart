import 'package:flutter/material.dart';
import 'package:gtd_app/app/glass.dart';
import 'package:gtd_app/app/theme.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/task/task_edit_dialog.dart';

/// 今日页（M1）：下一步行动列表，按优先级→截止日排序。AI 建议卡片 M2 引入。
/// 仓库约定：普通 Provider 无 watchByStatus 成员，改文件级 StreamProvider。
final _nextActionsProvider = StreamProvider<List<Task>>(
    (ref) => ref.watch(taskRepositoryProvider).watchByStatus(TaskStatus.nextAction));

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tasks = ref.watch(_nextActionsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.todayTitle)),
      body: tasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          final sorted = [...rows]..sort((a, b) {
              final pa = _priorityIndex(a.priority);
              final pb = _priorityIndex(b.priority);
              if (pa != pb) return pa.compareTo(pb);
              final da = a.dueDate ?? 1 << 62;
              final db2 = b.dueDate ?? 1 << 62;
              return da.compareTo(db2);
            });
          if (sorted.isEmpty) return Center(child: Text(l10n.emptyTasks));
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: sorted.length,
            itemBuilder: (context, i) => _TaskTile(task: sorted[i]),
          );
        },
      ),
    );
  }

  int _priorityIndex(String? p) => switch (p) {
        'high' => 0,
        'medium' => 1,
        'low' => 2,
        _ => 3,
      };
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: GlassContainer(
        color: tokens.cardSolid,
        blur: 5,
        saturate: 1.0,
        borderColor: tokens.stroke,
        borderRadius: BorderRadius.circular(AppTokens.radiusRow),
        shadow: tokens.shadowSm,
        child: ListTile(
          key: Key('task_tile_${task.id}'),
          title: Text(task.title),
          subtitle: task.dueDate == null
              ? null
              : Text(
                  DateTime.fromMillisecondsSinceEpoch(task.dueDate!)
                      .toString()
                      .substring(0, 10),
                  style: TextStyle(color: tokens.muted, fontSize: 12),
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
        ),
      ),
    );
  }
}
