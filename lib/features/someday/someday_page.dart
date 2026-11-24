import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/task/task_edit_dialog.dart';

/// 将来也许视图（验收⑤）：tasks.status = someday 的过滤视图。
/// 仓库约定：普通 Provider 无 watchByStatus 成员，改文件级 StreamProvider。
final _somedayProvider = StreamProvider<List<Task>>(
    (ref) => ref.watch(taskRepositoryProvider).watchByStatus(TaskStatus.someday));

class SomedayPage extends ConsumerWidget {
  const SomedayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tasks = ref.watch(_somedayProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSomeday)),
      body: tasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) => rows.isEmpty
            ? Center(child: Text(l10n.emptyTasks))
            : ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, i) => _SomedayTile(task: rows[i]),
              ),
      ),
    );
  }
}

class _SomedayTile extends ConsumerWidget {
  const _SomedayTile({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      key: Key('task_tile_${task.id}'),
      title: Text(task.title),
      leading: IconButton(
        key: Key('task_done_${task.id}'),
        icon: const Icon(Icons.check_circle_outline),
        tooltip: l10n.markDone,
        onPressed: () => ref.read(taskRepositoryProvider).complete(task.id),
      ),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => TaskEditDialog(task: task),
      ),
    );
  }
}
