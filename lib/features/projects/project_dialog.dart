import 'package:flutter/material.dart';
import 'package:settle_app/app/glass.dart';
import 'package:settle_app/app/theme.dart';
import 'package:settle_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settle_app/data/providers.dart';
import 'package:settle_app/data/tables.dart';

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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    return Dialog(
      constraints: const BoxConstraints(maxWidth: 560),
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
              widget.project == null ? l10n.newProject : l10n.editProject,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key: const Key('project_name_field'),
                      controller: _name,
                      decoration: InputDecoration(labelText: l10n.projectName),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('project_goal_field'),
                      controller: _goal,
                      minLines: 4,
                      maxLines: 10,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        labelText: l10n.projectGoal,
                        alignLabelWithHint: true,
                      ),
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
                  key: const Key('project_save'),
                  onPressed: _save,
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
