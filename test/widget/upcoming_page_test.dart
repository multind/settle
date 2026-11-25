import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/repositories/task_repository.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/upcoming/upcoming_page.dart';
import 'widget_utils.dart';

void main() {
  /// 固定时钟：页面头文案与数据层「今日末」边界共用同一时刻，
  /// 彻底消除 now 依赖与跨午夜竞态（与 TaskRepository 时钟注入同款口径）。
  final DateTime fixedNow = DateTime(2026, 11, 25, 10, 0);
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

  /// 今日 12:00 的 ms epoch（「今日内」任务用，基于 [fixedNow]）。
  int someDateMs() {
    return DateTime(fixedNow.year, fixedNow.month, fixedNow.day, 12)
        .millisecondsSinceEpoch;
  }

  /// [fixedNow] + [offset] 天 12:00 的 DateTime（未来日期任务用，组头 Key 与文案随其计算）。
  DateTime futureDay(int offset) {
    return DateTime(fixedNow.year, fixedNow.month, fixedNow.day + offset, 12);
  }

  int futureDayMs(int offset) => futureDay(offset).millisecondsSinceEpoch;

  /// 组装并 pump 即将页：页面时钟与数据层时钟（watchUpcoming「今日末」边界）
  /// 均注入 [fixedNow]，用例内日期全部基于同一时钟推导。
  Future<void> pumpPage(WidgetTester tester, TestEnv env) async {
    await tester.pumpWidget(env.wrap(
      UpcomingPage(now: () => fixedNow),
      extraOverrides: [
        taskRepositoryProvider.overrideWithValue(
            TaskRepository(env.db, now: () => fixedNow)),
      ],
    ));
    await tester.pump();
  }

  testWidgets('scheduled 未来按日分组（两个不同日期 → 两组，组头 Key/文本）', (tester) async {
    final env = await TestEnv.create();
    final d3 = futureDay(3);
    final d10 = futureDay(10);
    await insertTask(env, '三天后任务', 'next_action',
        scheduled: d3.millisecondsSinceEpoch);
    await insertTask(env, '十天后任务', 'next_action',
        scheduled: d10.millisecondsSinceEpoch);
    await pumpPage(tester, env);
    expect(find.text('三天后任务'), findsOneWidget);
    expect(find.text('十天后任务'), findsOneWidget);
    final key3 = Key('upcoming_date_header_${d3.year}_${d3.month}_${d3.day}');
    final key10 = Key('upcoming_date_header_${d10.year}_${d10.month}_${d10.day}');
    expect(find.byKey(key3), findsOneWidget);
    expect(find.byKey(key10), findsOneWidget);
    expect(find.textContaining('${d3.month}/${d3.day}'), findsOneWidget);
    expect(find.textContaining('${d10.month}/${d10.day}'), findsOneWidget);
    final y3 = tester.getTopLeft(find.byKey(key3)).dy;
    final y10 = tester.getTopLeft(find.byKey(key10)).dy;
    expect(y3 < y10, isTrue, reason: '日期分组升序：近日期组头在上');
    await env.db.close();
  });

  testWidgets('仅 dueDate 未来 → 生效日期=dueDate', (tester) async {
    final env = await TestEnv.create();
    final d5 = futureDay(5);
    await insertTask(env, '截止任务', 'next_action',
        dueDate: d5.millisecondsSinceEpoch);
    await pumpPage(tester, env);
    expect(find.text('截止任务'), findsOneWidget);
    expect(
        find.byKey(Key('upcoming_date_header_${d5.year}_${d5.month}_${d5.day}')),
        findsOneWidget);
    await env.db.close();
  });

  testWidgets('scheduled 与 dueDate 都在 → 生效日期=scheduled', (tester) async {
    final env = await TestEnv.create();
    final d3 = futureDay(3);
    final d10 = futureDay(10);
    await insertTask(env, '双日期任务', 'next_action',
        scheduled: d3.millisecondsSinceEpoch,
        dueDate: d10.millisecondsSinceEpoch);
    await pumpPage(tester, env);
    expect(find.text('双日期任务'), findsOneWidget);
    expect(
        find.byKey(Key('upcoming_date_header_${d3.year}_${d3.month}_${d3.day}')),
        findsOneWidget);
    expect(
        find.byKey(
            Key('upcoming_date_header_${d10.year}_${d10.month}_${d10.day}')),
        findsNothing);
    await env.db.close();
  });

  testWidgets('明天/后天使用友好文案', (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, '明日任务', 'next_action', scheduled: futureDayMs(1));
    await insertTask(env, '后日任务', 'next_action', scheduled: futureDayMs(2));
    await pumpPage(tester, env);
    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.text('Day after tomorrow'), findsOneWidget);
    await env.db.close();
  });

  testWidgets('今天/过去日期任务不出现', (tester) async {
    final env = await TestEnv.create();
    final todayStartMs =
        DateTime(fixedNow.year, fixedNow.month, fixedNow.day).millisecondsSinceEpoch;
    await insertTask(env, '今日任务', 'next_action', scheduled: someDateMs());
    await insertTask(env, '昨日任务', 'next_action', dueDate: todayStartMs - 1);
    await pumpPage(tester, env);
    expect(find.text('今日任务'), findsNothing);
    expect(find.text('昨日任务'), findsNothing);
    expect(find.text('No upcoming tasks.'), findsOneWidget);
    await env.db.close();
  });

  testWidgets('组内按 优先级→sortOrder 排序（sortOrder 为同级 tiebreak）', (tester) async {
    final env = await TestEnv.create();
    final day = futureDayMs(4);
    await insertTask(env, '低优先级前', 'next_action',
        priority: 'low', sortOrder: 1, scheduled: day);
    await insertTask(env, '高优先级后', 'next_action',
        priority: 'high', sortOrder: 5, scheduled: day);
    await insertTask(env, '中优先级中', 'next_action',
        priority: 'medium', sortOrder: 2, scheduled: day);
    await insertTask(env, '同级后', 'next_action', sortOrder: 20, scheduled: day);
    await insertTask(env, '同级前', 'next_action', sortOrder: 10, scheduled: day);
    await pumpPage(tester, env);
    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((t) => (t.title as Text).data)
        .toList();
    expect(titles, ['高优先级后', '中优先级中', '低优先级前', '同级前', '同级后']);
    await env.db.close();
  });

  testWidgets('空态文案', (tester) async {
    final env = await TestEnv.create();
    await pumpPage(tester, env);
    expect(find.text('No upcoming tasks.'), findsOneWidget);
    await env.db.close();
  });
}
