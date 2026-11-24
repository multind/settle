import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/core/models/task_draft.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/task/task_form_fields.dart';

/// 编辑既有 Task（从任务列表点击打开；状态不可改，改状态走完成/重开按钮）。
class TaskEditDialog extends ConsumerStatefulWidget {
  const TaskEditDialog({super.key, required this.task});

  final Task task;

  @override
  ConsumerState<TaskEditDialog> createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends ConsumerState<TaskEditDialog> {
  final _formKey = GlobalKey<TaskFormFieldsState>();

  TaskDraft _initialDraft() {
    final t = widget.task;
    return TaskDraft(
      title: t.title,
      notes: t.notes,
      status: TaskStatus.fromStorage(t.status),
      waitingOn: t.waitingOn,
      dueDate: t.dueDate == null ? null : DateTime.fromMillisecondsSinceEpoch(t.dueDate!),
      scheduled: t.scheduled == null ? null : DateTime.fromMillisecondsSinceEpoch(t.scheduled!),
      energy: EnergyLevel.fromStorageOrNull(t.energy),
      priority: PriorityLevel.fromStorageOrNull(t.priority),
      projectId: t.projectId,
      contextId: t.contextId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tagStream = ref.watch(taskRepositoryProvider).watchTags(widget.task.id);
    return StreamBuilder<List<Tag>>(
      stream: tagStream,
      builder: (context, snapshot) {
        final tagIds = snapshot.data?.map((x) => x.id).toSet() ?? const <int>{};
        return AlertDialog(
          title: Text(l10n.editTask),
          content: SingleChildScrollView(
            child: TaskFormFields(
              key: _formKey,
              initial: _initialDraft(),
              initialTagIds: tagIds,
              allowStatusChange: false,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              key: const Key('task_edit_save'),
              onPressed: () async {
                final draft = _formKey.currentState!.validate();
                if (draft == null) return;
                await ref.read(taskRepositoryProvider).update(widget.task.id, draft);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }
}
