import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/projects/projects_page.dart';
import 'widget_utils.dart';

void main() {
  Future<int> seedProject(TestEnv env, String name) async {
    return env.db.into(env.db.projects).insert(ProjectsCompanion.insert(
      name: name,
      status: 'active',
      createdAt: 1,
      updatedAt: 1,
    ));
  }

  Future<int> seedTask(TestEnv env, int projectId, String title) async {
    return env.db.into(env.db.tasks).insert(TasksCompanion.insert(
      title: title,
      status: 'next_action',
      projectId: Value(projectId),
      createdAt: 1,
      updatedAt: 1,
    ));
  }

  testWidgets('项目卡片展示名称/目标/其下任务（验收⑤）', (tester) async {
    final env = await TestEnv.create();
    final p = await seedProject(env, '客户交付');
    await seedTask(env, p, '写初稿');
    await tester.pumpWidget(env.wrap(const ProjectsPage()));
    await tester.pumpAndSettle();
    expect(find.text('客户交付'), findsOneWidget);
    expect(find.text('写初稿'), findsOneWidget);
    await env.db.close();
  });

  testWidgets('新建项目（FAB）→ 列表出现（验收⑤）', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const ProjectsPage()));
    await tester.pump();
    await tester.tap(find.byKey(const Key('new_project_fab')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('project_name_field')), '新项目');
    await tester.tap(find.byKey(const Key('project_save')));
    await tester.pumpAndSettle();
    expect(find.text('新项目'), findsOneWidget);
    expect(await env.db.select(env.db.projects).get(), hasLength(1));
    await env.db.close();
  });

  testWidgets('删除项目走二次确认并级联删除任务（验收⑤/§5.2）', (tester) async {
    final env = await TestEnv.create();
    final p = await seedProject(env, '客户交付');
    final t = await seedTask(env, p, '写初稿');
    await tester.pumpWidget(env.wrap(const ProjectsPage()));
    await tester.pump();
    await tester.tap(find.byKey(Key('delete_project_$p')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await env.db.select(env.db.tasks).get(), hasLength(1));
    await tester.tap(find.byKey(Key('delete_project_$p')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_delete_project')));
    await tester.pumpAndSettle();
    expect(await env.db.select(env.db.projects).get(), isEmpty);
    expect(await env.db.select(env.db.tasks).get(), isEmpty);
    expect(await env.db.select(env.db.taskTags).get(), isEmpty);
    expect(t, isPositive);
    await env.db.close();
  });
}
