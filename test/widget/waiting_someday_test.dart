import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/someday/someday_page.dart';
import 'package:gtd_app/features/waiting/waiting_page.dart';
import 'widget_utils.dart';

void main() {
  Future<int> insertTask(TestEnv env, String title, String status, {String? waitingOn}) async {
    return env.db.into(env.db.tasks).insert(TasksCompanion.insert(
      title: title,
      status: status,
      waitingOn: Value(waitingOn),
      createdAt: 1,
      updatedAt: 1,
    ));
  }

  testWidgets('等待视图只显示 waiting 任务及其 waiting_on（验收⑤）', (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, '跟进报销', 'waiting', waitingOn: '财务部');
    await insertTask(env, '写周报', 'next_action');
    await insertTask(env, '学做饭', 'someday');
    await tester.pumpWidget(env.wrap(const WaitingPage()));
    await tester.pump();
    expect(find.text('跟进报销'), findsOneWidget);
    expect(find.text('财务部'), findsOneWidget);
    expect(find.text('写周报'), findsNothing);
    expect(find.text('学做饭'), findsNothing);
    await env.db.close();
  });

  testWidgets('将来也许视图只显示 someday 任务（验收⑤）', (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, '学做饭', 'someday');
    await insertTask(env, '写周报', 'next_action');
    await tester.pumpWidget(env.wrap(const SomedayPage()));
    await tester.pump();
    expect(find.text('学做饭'), findsOneWidget);
    expect(find.text('写周报'), findsNothing);
    await env.db.close();
  });

  testWidgets('等待任务完成按钮置 done（§5.2）', (tester) async {
    final env = await TestEnv.create();
    final id = await insertTask(env, '跟进报销', 'waiting', waitingOn: '财务部');
    await tester.pumpWidget(env.wrap(const WaitingPage()));
    await tester.pump();
    await tester.tap(find.byKey(Key('task_done_$id')));
    await tester.pumpAndSettle();
    final row = await (env.db.select(env.db.tasks)..where((t) => t.id.equals(id))).getSingle();
    expect(row.status, 'done');
    expect(row.waitingOn, isNull);
    expect(find.text('跟进报销'), findsNothing);
    await env.db.close();
  });
}
