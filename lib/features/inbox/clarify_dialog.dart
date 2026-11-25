import 'package:flutter/material.dart';
import 'package:gtd_app/app/glass.dart';
import 'package:gtd_app/app/theme.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/core/models/clarify_decision.dart';
import 'package:gtd_app/core/models/task_draft.dart';
import 'package:gtd_app/core/workflow/clarify_service.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/task/task_form_fields.dart';

/// 理清向导（规格 §7.2）：行动 / 项目 / 删除 三选一，确认后走 ClarifyService。
class ClarifyDialog extends ConsumerStatefulWidget {
  const ClarifyDialog({super.key, required this.item});

  final InboxItem item;

  @override
  ConsumerState<ClarifyDialog> createState() => _ClarifyDialogState();
}

enum _Decision { task, project, delete }

class _ClarifyDialogState extends ConsumerState<ClarifyDialog> {
  _Decision _decision = _Decision.task;
  final _projectName = TextEditingController();
  final _projectGoal = TextEditingController();
  final _taskFormKey = GlobalKey<TaskFormFieldsState>();

  @override
  void dispose() {
    _projectName.dispose();
    _projectGoal.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final item = widget.item;
    final service = ClarifyService(
      ref.read(databaseProvider),
      ref.read(inboxRepositoryProvider),
      ref.read(taskRepositoryProvider),
      ref.read(projectRepositoryProvider),
    );
    switch (_decision) {
      case _Decision.task:
        final draft = _taskFormKey.currentState!.validate();
        if (draft == null) return;
        await service.clarify(item, ClarifyToTask(draft));
      case _Decision.project:
        final name = _projectName.text.trim();
        if (name.isEmpty) return;
        await service.clarify(
          item,
          ClarifyToProject(
            name: name,
            goal: _projectGoal.text.trim().isEmpty ? null : _projectGoal.text.trim(),
          ),
        );
      case _Decision.delete:
        await service.clarify(item, ClarifyDelete());
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: GlassContainer(
        color: tokens.card,
        blur: 12,
        saturate: 1.8,
        borderColor: tokens.stroke,
        borderRadius: BorderRadius.circular(AppTokens.radiusContainer),
        shadow: tokens.shadow,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.clarify,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.item.rawText, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SegmentedButton<_Decision>(
                      key: const Key('clarify_decision'),
                      segments: [
                        ButtonSegment(value: _Decision.task, label: Text(l10n.decisionAction)),
                        ButtonSegment(value: _Decision.project, label: Text(l10n.decisionProject)),
                        ButtonSegment(value: _Decision.delete, label: Text(l10n.decisionDelete)),
                      ],
                      selected: {_decision},
                      onSelectionChanged: (s) => setState(() => _decision = s.first),
                    ),
                    const SizedBox(height: 12),
                    if (_decision == _Decision.task)
                      TaskFormFields(key: _taskFormKey, initial: TaskDraft(title: widget.item.rawText))
                    else if (_decision == _Decision.project) ...[
                      TextField(
                        key: const Key('clarify_project_name'),
                        controller: _projectName,
                        decoration: InputDecoration(labelText: l10n.projectName),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('clarify_project_goal'),
                        controller: _projectGoal,
                        decoration: InputDecoration(labelText: l10n.projectGoal),
                      ),
                    ] else
                      Text(
                        l10n.confirmDeleteInbox,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                  ],
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
                  key: const Key('clarify_confirm'),
                  onPressed: _confirm,
                  minimumSize: const Size(72, 40),
                  child: Text(l10n.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
