import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/projects/project_dialog.dart';
import 'package:gtd_app/features/task/task_edit_dialog.dart';

/// 项目视图（验收⑤）：项目卡片 + 其下 Task。
/// 仓库约定：普通 Provider 无 watchAll/watchByProject 成员，改文件级 StreamProvider。
final _projectsProvider = StreamProvider<List<Project>>(
    (ref) => ref.watch(projectRepositoryProvider).watchAll());
final _projectTasksProvider = StreamProvider.family<List<Task>, int>(
    (ref, projectId) => ref.watch(taskRepositoryProvider).watchByProject(projectId));

class ProjectsPage extends ConsumerWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final projects = ref.watch(_projectsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navProjects)),
      floatingActionButton: FloatingActionButton.small(
        key: const Key('new_project_fab'),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const ProjectDialog(),
        ),
        child: const Icon(Icons.add),
      ),
      body: projects.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => list.isEmpty
            ? Center(child: Text(l10n.emptyTasks))
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) => _ProjectCard(project: list[i]),
              ),
      ),
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  const _ProjectCard({required this.project});
  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tasks = ref.watch(_projectTasksProvider(project.id));
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          ListTile(
            key: Key('project_card_${project.id}'),
            title: Text(project.name),
            subtitle: project.goal == null ? null : Text(project.goal!),
            leading: Icon(
              project.status == 'done' ? Icons.task_alt : Icons.folder,
              color: project.status == 'done' ? Colors.green : null,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: Key('edit_project_${project.id}'),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n.editProject,
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => ProjectDialog(project: project),
                  ),
                ),
                IconButton(
                  key: Key('delete_project_${project.id}'),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.delete,
                  onPressed: () => _confirmDelete(context, ref, l10n),
                ),
              ],
            ),
          ),
          ...tasks.when(
            data: (rows) => rows.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(l10n.emptyTasks),
                    ),
                  ]
                : [for (final t in rows) _taskTile(context, ref, l10n, t)],
            loading: () => const [],
            error: (_, __) => const [],
          ),
        ],
      ),
    );
  }

  Widget _taskTile(
      BuildContext context, WidgetRef ref, AppLocalizations l10n, Task t) {
    return ListTile(
      dense: true,
      title: Text(t.title),
      trailing: IconButton(
        icon: const Icon(Icons.check_circle_outline),
        tooltip: l10n.markDone,
        onPressed: () => ref.read(taskRepositoryProvider).complete(t.id),
      ),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => TaskEditDialog(task: t),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteProject),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirm_delete_project'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(projectRepositoryProvider).delete(project.id);
    }
  }
}
