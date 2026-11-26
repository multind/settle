import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settle_app/data/providers.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/task/task_list_view.dart';
import 'package:settle_app/i18n/l10n/app_localizations.dart';

/// 随时视图（index 3）：`watchAnytime`（next_action 且 scheduled/dueDate 均 null），
/// 无日期 next_action 聚合（GTD「随时可做」）。
/// 公共组件 `TaskListView` 内统一排序（优先级→sortOrder→id 终局 tiebreak）；
/// 行不显示日期（随时任务无日期）；完成进日志（数据层 complete 已写 completedAt）。
/// 仓库约定：普通 Provider 无 watchByStatus 成员，改文件级 StreamProvider。
final _anytimeProvider = StreamProvider<List<Task>>(
    (ref) => ref.watch(taskRepositoryProvider).watchAnytime());

/// 随时页批量操作集（Task 2 接线 onAction 实现；本 Task 仅展示按钮）。
const _batchActions = [
  TaskListAction.complete,
  TaskListAction.delete,
  TaskListAction.setDate,
  TaskListAction.move,
];

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
          return TaskListView(
            tasks: rows,
            reorderEnabled: true,
            selectionEnabled: true,
            focusEnabled: true,
            actions: _batchActions,
          );
        },
      ),
    );
  }
}
