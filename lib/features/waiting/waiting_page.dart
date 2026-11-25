import 'package:flutter/material.dart';
import 'package:gtd_app/app/glass.dart';
import 'package:gtd_app/app/theme.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/task/task_edit_dialog.dart';

/// 等待视图（验收⑤）：tasks.status = waiting 的过滤视图 + waiting_on 展示（§5.3②）。
/// 仓库约定：普通 Provider 无 watchByStatus 成员，改文件级 StreamProvider。
final _waitingProvider = StreamProvider<List<Task>>(
    (ref) => ref.watch(taskRepositoryProvider).watchByStatus(TaskStatus.waiting));

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
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: rows.length,
                itemBuilder: (context, i) => _WaitingTile(task: rows[i]),
              ),
      ),
    );
  }
}

class _WaitingTile extends ConsumerWidget {
  const _WaitingTile({required this.task});
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
          subtitle: task.waitingOn == null
              ? null
              : Text(
                  task.waitingOn!,
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
