import 'package:flutter/material.dart';
import 'package:settle_app/app/glass.dart';
import 'package:settle_app/app/theme.dart';
import 'package:settle_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settle_app/core/enums.dart';
import 'package:settle_app/core/models/task_draft.dart';
import 'package:settle_app/data/providers.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/task/task_form_fields.dart';

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
      repeatRule: t.repeatRule,
      reminderAt: t.reminderAt == null ? null : DateTime.fromMillisecondsSinceEpoch(t.reminderAt!),
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
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: GlassContainer(
            color: Theme.of(context).colorScheme.surface, // 测试环境下不依赖扩展的 card
            blur: 12,
            saturate: 1.8,
            borderColor: Theme.of(context).colorScheme.outline, // stroke
            borderRadius: BorderRadius.circular(AppTokens.radiusContainer),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.editTask,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: TaskFormFields(
                      key: _formKey,
                      initial: _initialDraft(),
                      initialTagIds: tagIds,
                      allowStatusChange: false,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: 12),
                    GradientButton(
                      key: const Key('task_edit_save'),
                      onPressed: () async {
                        final draft = _formKey.currentState!.validate();
                        if (draft == null) return;
                        await ref.read(taskRepositoryProvider).update(widget.task.id, draft);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      minimumSize: const Size(72, 40),
                      child: Text(l10n.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
