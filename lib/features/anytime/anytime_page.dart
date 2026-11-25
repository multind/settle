import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/app/glass.dart';
import 'package:gtd_app/app/theme.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/task/task_edit_dialog.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';

/// 随时视图（index 3）：`watchAnytime`（next_action 且 scheduled/dueDate 均 null），
/// 无日期 next_action 聚合（GTD「随时可做」），按 优先级→sortOrder 排序。
/// 行不显示日期（随时任务无日期）；完成进日志（数据层 complete 已写 completedAt）。
/// 仓库约定：普通 Provider 无 watchByStatus 成员，改文件级 StreamProvider。
final _anytimeProvider = StreamProvider<List<Task>>(
    (ref) => ref.watch(taskRepositoryProvider).watchAnytime());

class AnytimePage extends ConsumerWidget {
  const AnytimePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tasks = ref.watch(_anytimeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navAnytime)),
      body: tasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          if (rows.isEmpty) return Center(child: Text(l10n.anytimeEmpty));
          final sorted = rows.toList()..sort(_compare);
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: sorted.map((t) => _TaskTile(task: t)).toList(),
          );
        },
      ),
    );
  }

  /// 优先级 → sortOrder 升序（随时任务无日期，用 sortOrder 而非生效日期）。
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

/// 随时行（v0.2 样式，同今日页 _TaskTile）：完成钮 / 点击编辑 / GlassContainer 圆角零阴影。
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
