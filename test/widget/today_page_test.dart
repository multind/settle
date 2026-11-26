import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/today/today_page.dart';
import 'widget_utils.dart';

void main() {
  Future<int> insertTask(TestEnv env, String title, String status,
      {String? priority, int? dueDate, int? scheduled}) async {
    return env.db.into(env.db.tasks).insert(TasksCompanion.insert(
      title: title,
      status: status,
      priority: Value(priority),
      dueDate: Value(dueDate),
      scheduled: Value(scheduled),
      createdAt: 1,
      updatedAt: 1,
    ));
  }

  /// 今日 00:00 的 ms epoch（与页面 _todayStart 同口径）。
  int todayStartMs() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
  }

  /// 今日 12:00 的 ms epoch（「今日内」有日期任务用）。
  int todayNoonMs() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 12).millisecondsSinceEpoch;
  }

  /// 昨日任意时刻（todayStartMs - 1 = 昨日 23:59:59.999，必在今日之前）。
  int yesterdayMs() => todayStartMs() - 1;

  testWidgets('有日期 next_action（dueDate=今天 或 scheduled=今天）出现在今日', (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, '截止今日', 'next_action', dueDate: todayNoonMs());
    await insertTask(env, '计划今日', 'next_action', scheduled: todayNoonMs());
    await tester.pumpWidget(env.wrap(const TodayPage()));
    await tester.pump();
    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((t) => (t.title as Text).data)
        .toList();
    expect(titles, containsAll(['截止今日', '计划今日']));
    expect(find.text('1 overdue'), findsNothing);
    await env.db.close();
  });

  testWidgets('无日期 next_action 不再出现在今日（进随时，由 anytime_page_test 覆盖）',
      (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, '无日期任务', 'next_action');
    await tester.pumpWidget(env.wrap(const TodayPage()));
    await tester.pump();
    expect(find.text('无日期任务'), findsNothing);
    expect(find.text('Nothing scheduled today.'), findsOneWidget);
    await env.db.close();
  });

  testWidgets('逾期任务（dueDate=昨天）进入逾期区置顶，区标题显示', (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, '逾期任务', 'next_action', dueDate: yesterdayMs());
    await insertTask(env, '今日任务', 'next_action', scheduled: todayNoonMs());
    await tester.pumpWidget(env.wrap(const TodayPage()));
    await tester.pump();
    expect(find.text('1 overdue'), findsOneWidget);
    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((t) => (t.title as Text).data)
        .toList();
    expect(titles, ['逾期任务', '今日任务']);
    await env.db.close();
  });

  testWidgets('今日区按 优先级→生效日期 升序', (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, '低优先级晚些', 'next_action',
        priority: 'low', dueDate: todayNoonMs());
    await insertTask(env, '高优先级早些', 'next_action',
        priority: 'high', scheduled: todayNoonMs());
    await tester.pumpWidget(env.wrap(const TodayPage()));
    await tester.pump();
    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((t) => (t.title as Text).data)
        .toList();
    expect(titles, ['高优先级早些', '低优先级晚些']);
    await env.db.close();
  });

  testWidgets('点击完成按钮将任务置为 done（§5.2）', (tester) async {
    final env = await TestEnv.create();
    final id = await insertTask(env, '写周报', 'next_action', dueDate: todayNoonMs());
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
    expect(find.text('Nothing scheduled today.'), findsOneWidget);
    await env.db.close();
  });
}
