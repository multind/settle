import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';

/// 新建/编辑项目。
class ProjectDialog extends ConsumerStatefulWidget {
  const ProjectDialog({super.key, this.project});

  final Project? project;

  @override
  ConsumerState<ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends ConsumerState<ProjectDialog> {
  late final TextEditingController _name;
  late final TextEditingController _goal;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.project?.name ?? '');
    _goal = TextEditingController(text: widget.project?.goal ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final repo = ref.read(projectRepositoryProvider);
    final goal = _goal.text.trim().isEmpty ? null : _goal.text.trim();
    final p = widget.project;
    if (p == null) {
      await repo.create(name: name, goal: goal);
    } else {
      await repo.updateNameAndGoal(p.id, name: name, goal: goal);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.project == null ? l10n.newProject : l10n.editProject),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('project_name_field'),
            controller: _name,
            decoration: InputDecoration(labelText: l10n.projectName),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('project_goal_field'),
            controller: _goal,
            decoration: InputDecoration(labelText: l10n.projectGoal),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('project_save'),
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
