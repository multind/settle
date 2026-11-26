import 'package:flutter/material.dart';
import 'package:settle_app/app/theme.dart';
import 'package:settle_app/core/enums.dart';
import 'package:settle_app/data/providers.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/task/task_list_view.dart';
import 'package:settle_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 等待视图（验收⑤）：tasks.status = waiting 的过滤视图 + waiting_on 展示（§5.3②）。
/// 公共组件 `TaskListView`（无重排，waiting_on 经 subtitleBuilder 注入）。
/// 仓库约定：普通 Provider 无 watchByStatus 成员，改文件级 StreamProvider。
final _waitingProvider = StreamProvider<List<Task>>(
    (ref) => ref.watch(taskRepositoryProvider).watchByStatus(TaskStatus.waiting));

/// 等待页批量操作集（Task 2 接线 onAction 实现；本 Task 仅展示按钮）。
const _batchActions = [
  TaskListAction.complete,
  TaskListAction.delete,
  TaskListAction.setDate,
  TaskListAction.move,
];

class WaitingPage extends ConsumerWidget {
  const WaitingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tasks = ref.watch(_waitingProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navWaiting)),
      body: tasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) => rows.isEmpty
            ? Center(child: Text(l10n.emptyTasks))
            : TaskListView(
                tasks: rows,
                reorderEnabled: false,
                selectionEnabled: true,
                focusEnabled: true,
                actions: _batchActions,
                subtitleBuilder: (context, t) {
                  if (t.waitingOn == null) return null;
                  final isLight =
                      Theme.of(context).brightness == Brightness.light;
                  final tokens = isLight ? AppTokens.light : AppTokens.dark;
                  return Text(
                    t.waitingOn!,
                    style: TextStyle(color: tokens.muted, fontSize: 12),
                  );
                },
              ),
      ),
    );
  }
}
