import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/today/today_page.dart';
import 'widget_utils.dart';

void main() {
  Future<int> insertTask(TestEnv env, String title, String status,
      {String? priority, int? dueDate}) async {
    return env.db.into(env.db.tasks).insert(TasksCompanion.insert(
      title: title,
      status: status,
      priority: Value(priority),
      dueDate: Value(dueDate),
      createdAt: 1,
      updatedAt: 1,
    ));
  }

  testWidgets('只显示 next_action，且按优先级高→低排序（规格 §7.2 今日视图）', (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, '低优先级任务', 'next_action', priority: 'low');
    await insertTask(env, '高优先级任务', 'next_action', priority: 'high');
    await insertTask(env, '等待中的任务', 'waiting');
    await insertTask(env, '已完成', 'done');
    await tester.pumpWidget(env.wrap(const TodayPage()));
    await tester.pump();
    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((t) => (t.title as Text).data)
        .toList();
    expect(titles, ['高优先级任务', '低优先级任务']);
    expect(find.text('等待中的任务'), findsNothing);
    expect(find.text('已完成'), findsNothing);
    await env.db.close();
  });

  testWidgets('点击完成按钮将任务置为 done（§5.2）', (tester) async {
    final env = await TestEnv.create();
    final id = await insertTask(env, '写周报', 'next_action');
    await tester.pumpWidget(env.wrap(const TodayPage()));
    await tester.pump();
    await tester.tap(find.byKey(Key('task_done_$id')));
    await tester.pumpAndSettle();
    final row =
        await (env.db.select(env.db.tasks)..where((t) => t.id.equals(id))).getSingle();
    expect(row.status, 'done');
    expect(find.text('写周报'), findsNothing);
    await env.db.close();
  });

  testWidgets('空态文案', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const TodayPage()));
    await tester.pump();
    expect(find.text('Nothing here yet.'), findsOneWidget);
    await env.db.close();
  });
}
