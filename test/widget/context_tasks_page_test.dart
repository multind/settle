import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/contexts/context_tasks_page.dart';
import 'package:settle_app/features/task/task_list_view.dart';
import 'widget_utils.dart';

void main() {
  /// 取种子情境（@电脑）。
  Future<Context> seedContext(TestEnv env) async =>
      (await env.db.select(env.db.contexts).get()).first;

  Future<int> insertTask(TestEnv env, String title, int contextId) async {
    return env.db.into(env.db.tasks).insert(TasksCompanion.insert(
          title: title,
          status: 'next_action',
          contextId: Value(contextId),
          createdAt: 1,
          updatedAt: 1,
        ));
  }

  /// 桌面平台覆盖：快捷键（focusEnabled）仅桌面启用。
  void useDesktop() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
  }

  testWidgets('任务列表渲染：仅显示该情境的任务', (tester) async {
    final env = await TestEnv.create();
    final c = await seedContext(env);
    final otherId = await env.db
        .into(env.db.contexts)
        .insert(ContextsCompanion.insert(name: '@工作'));
    await insertTask(env, '情境任务', c.id);
    await insertTask(env, '工作任务', otherId);
    await tester.pumpWidget(env.wrap(ContextTasksPage(context: c)));
    await tester.pump();
    expect(find.text('情境任务'), findsOneWidget);
    expect(find.text('工作任务'), findsNothing);
    await env.db.close();
  });

  testWidgets('空态：情境无任务 → PageRuleHint + contextTasksEmpty',
      (tester) async {
    final env = await TestEnv.create();
    final c = await seedContext(env);
    await tester.pumpWidget(env.wrap(ContextTasksPage(context: c)));
    await tester.pump();
    expect(find.byKey(const Key('page_rule_hint')), findsOneWidget);
    expect(find.text('No tasks in this context'), findsOneWidget);
    await env.db.close();
  });

  testWidgets('批量完成生效：长按 → 完成 → done + 空态', (tester) async {
    final env = await TestEnv.create();
    final c = await seedContext(env);
    final id = await insertTask(env, '情境任务', c.id);
    await tester.pumpWidget(env.wrap(ContextTasksPage(context: c)));
    await tester.pump();
    await tester.longPress(find.text('情境任务'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('task_selection_action_complete')));
    await tester.pumpAndSettle();
    final row = await (env.db.select(env.db.tasks)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    expect(row.status, 'done');
    expect(find.text('情境任务'), findsNothing);
    expect(find.text('No tasks in this context'), findsOneWidget);
    await env.db.close();
  });

  testWidgets('批量删除生效：确认后硬删除', (tester) async {
    final env = await TestEnv.create();
    final c = await seedContext(env);
    final id = await insertTask(env, '情境任务', c.id);
    await tester.pumpWidget(env.wrap(ContextTasksPage(context: c)));
    await tester.pump();
    await tester.longPress(find.text('情境任务'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('task_selection_action_delete')));
    await tester.pumpAndSettle();
    // 确认对话框（TaskListView 内置默认处理，复用 logbook_confirm_delete Key）。
    expect(find.byKey(const Key('logbook_confirm_delete')), findsOneWidget);
    await tester.tap(find.byKey(const Key('logbook_confirm_delete')));
    await tester.pumpAndSettle();
    final rows = await env.db.select(env.db.tasks).get();
    expect(rows.map((r) => r.id), isNot(contains(id)));
    expect(find.text('No tasks in this context'), findsOneWidget);
    await env.db.close();
  });

  testWidgets('桌面：焦点快捷键可用（J 下移焦点）', (tester) async {
    useDesktop();
    final env = await TestEnv.create();
    final c = await seedContext(env);
    await insertTask(env, 'Task A', c.id);
    await insertTask(env, 'Task B', c.id);
    await tester.pumpWidget(env.wrap(ContextTasksPage(context: c)));
    await tester.pump();
    final state = tester.state<TaskListViewState>(find.byType(TaskListView));
    state.focusRow(0);
    await tester.pump();
    expect(state.focusIndex, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await tester.pump();
    expect(state.focusIndex, 1);
    await env.db.close();
  });
}
