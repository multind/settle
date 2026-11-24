import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/task/task_edit_dialog.dart';
import 'widget_utils.dart';

void main() {
  testWidgets('编辑任务：改标题与优先级并保存（验收④）', (tester) async {
    final env = await TestEnv.create();
    final id = await env.db.into(env.db.tasks).insert(TasksCompanion.insert(
      title: '旧标题',
      status: 'next_action',
      createdAt: 1,
      updatedAt: 1,
    ));
    await tester.pumpWidget(env.wrap(_EditHost(taskId: id)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_edit')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('task_title_field')), '新标题');
    await tester.tap(find.byKey(const Key('task_priority_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('high').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task_edit_save')));
    await tester.pumpAndSettle();
    final row = await (env.db.select(env.db.tasks)..where((t) => t.id.equals(id))).getSingle();
    expect(row.title, '新标题');
    expect(row.priority, 'high');
    expect(row.status, 'next_action');
    await env.db.close();
  });

  testWidgets('取消不改动数据', (tester) async {
    final env = await TestEnv.create();
    final id = await env.db.into(env.db.tasks).insert(TasksCompanion.insert(
      title: '标题',
      status: 'next_action',
      createdAt: 1,
      updatedAt: 1,
    ));
    await tester.pumpWidget(env.wrap(_EditHost(taskId: id)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_edit')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('task_title_field')), '不应保存');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    final row = await (env.db.select(env.db.tasks)..where((t) => t.id.equals(id))).getSingle();
    expect(row.title, '标题');
    await env.db.close();
  });
}

class _EditHost extends ConsumerWidget {
  const _EditHost({required this.taskId});
  final int taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(taskRepositoryProvider);
    return Scaffold(
      body: FutureBuilder<Task?>(
        future: repo.byId(taskId),
        builder: (context, snapshot) {
          final task = snapshot.data;
          if (task == null) return const SizedBox.shrink();
          return Center(
            child: FilledButton(
              key: const Key('open_edit'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => TaskEditDialog(task: task),
              ),
              child: const Text('edit'),
            ),
          );
        },
      ),
    );
  }
}
