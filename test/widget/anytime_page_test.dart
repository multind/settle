import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/anytime/anytime_page.dart';
import 'widget_utils.dart';

void main() {
  Future<int> insertTask(TestEnv env, String title, String status,
      {String? priority, int? dueDate, int? scheduled, int? sortOrder}) async {
    return env.db.into(env.db.tasks).insert(TasksCompanion.insert(
      title: title,
      status: status,
      priority: Value(priority),
      dueDate: Value(dueDate),
      scheduled: Value(scheduled),
      sortOrder: sortOrder == null ? const Value.absent() : Value(sortOrder),
      createdAt: 1,
      updatedAt: 1,
    ));
  }

  /// 今日 12:00 的 ms epoch（「某日」有日期任务用）。
  int someDateMs() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 12).millisecondsSinceEpoch;
  }

  testWidgets('无日期 next_action 显示在随时页', (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, '无日期任务', 'next_action');
    await tester.pumpWidget(env.wrap(const AnytimePage()));
    await tester.pump();
    expect(find.text('无日期任务'), findsOneWidget);
    await env.db.close();
  });

  testWidgets('有日期 next_action 不显示（scheduled 与 dueDate 各一）', (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, '计划任务', 'next_action', scheduled: someDateMs());
    await insertTask(env, '截止任务', 'next_action', dueDate: someDateMs());
    await tester.pumpWidget(env.wrap(const AnytimePage()));
    await tester.pump();
    expect(find.text('计划任务'), findsNothing);
    expect(find.text('截止任务'), findsNothing);
    expect(find.text('Tasks you\'ll do soon, without a fixed day, live here.'),
        findsOneWidget);
    await env.db.close();
  });

  testWidgets('按 优先级→sortOrder 排序（sortOrder 为同级 tiebreak）', (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, '低优先级前', 'next_action',
        priority: 'low', sortOrder: 1);
    await insertTask(env, '高优先级后', 'next_action',
        priority: 'high', sortOrder: 5);
    await insertTask(env, '中优先级中', 'next_action',
        priority: 'medium', sortOrder: 2);
    // 同级（无优先级）按 sortOrder 升序。
    await insertTask(env, '同级后', 'next_action', sortOrder: 20);
    await insertTask(env, '同级前', 'next_action', sortOrder: 10);
    await tester.pumpWidget(env.wrap(const AnytimePage()));
    await tester.pump();
    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((t) => (t.title as Text).data)
        .toList();
    expect(titles, ['高优先级后', '中优先级中', '低优先级前', '同级前', '同级后']);
    await env.db.close();
  });

  testWidgets('点击完成按钮将任务置为 done 且不再出现（§5.2）', (tester) async {
    final env = await TestEnv.create();
    final id = await insertTask(env, '随时任务', 'next_action');
    await tester.pumpWidget(env.wrap(const AnytimePage()));
    await tester.pump();
    await tester.tap(find.byKey(Key('task_done_$id')));
    await tester.pumpAndSettle();
    final row =
        await (env.db.select(env.db.tasks)..where((t) => t.id.equals(id))).getSingle();
    expect(row.status, 'done');
    expect(find.text('随时任务'), findsNothing);
    expect(find.text('Tasks you\'ll do soon, without a fixed day, live here.'),
        findsOneWidget);
    await env.db.close();
  });

  testWidgets('空态文案', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const AnytimePage()));
    await tester.pump();
    expect(find.text('Tasks you\'ll do soon, without a fixed day, live here.'),
        findsOneWidget);
    await env.db.close();
  });
}
