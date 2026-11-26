import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/gestures.dart' show kLongPressTimeout, kPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/data/providers.dart';
import 'package:settle_app/data/repositories/task_repository.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/upcoming/upcoming_page.dart';
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
    expect(
        find.text('Keep meetings and deadlines here. Drag a task onto a date header to schedule it.'),
        findsOneWidget);
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
    expect(
        find.text('Keep meetings and deadlines here. Drag a task onto a date header to schedule it.'),
        findsOneWidget);
    await env.db.close();
  });

  // —— Task 3：拖到日期（DragTarget 落点 = 日期头，Draggable 源 = 任务行）——

  Key dropKey(DateTime d) =>
      Key('upcoming_date_drop_${d.year}_${d.month}_${d.day}');
  Key headerKey(DateTime d) =>
      Key('upcoming_date_header_${d.year}_${d.month}_${d.day}');
  Key highlightKey(DateTime d) =>
      Key('upcoming_date_highlight_${d.year}_${d.month}_${d.day}');

  /// 从 [source] 行中心拖到 [target] 中心（快拖：不等待长按，Draggable 立即接受），
  /// 在 target 上悬停一帧后松开。返回手势以便调用方中途断言（悬停高亮）。
  Future<TestGesture> dragRowTo(WidgetTester tester, String sourceTitle,
      DateTime target) async {
    final src = tester.getCenter(find.text(sourceTitle));
    final dst = tester.getCenter(find.byKey(dropKey(target)));
    final gesture = await tester.startGesture(src);
    await tester.pump();
    await gesture.moveBy(dst - src);
    await tester.pump();
    return gesture;
  }

  /// 日期头悬停描边颜色（恒定 2px Border，未悬停 = 透明）。
  Color headerBorderColor(WidgetTester tester, DateTime d) {
    final box = tester.widget<DecoratedBox>(find.byKey(highlightKey(d)));
    return ((box.decoration as BoxDecoration).border as Border).top.color;
  }

  testWidgets('拖任务到另一日期头 → scheduled 写入目标日、分组即时变化（dueDate 保留、不重排）',
      (tester) async {
    final env = await TestEnv.create();
    final d3 = futureDay(3);
    final d10 = futureDay(10);
    final a = await insertTask(env, '三天后任务', 'next_action',
        scheduled: d3.millisecondsSinceEpoch,
        dueDate: d10.millisecondsSinceEpoch,
        sortOrder: 1);
    final b = await insertTask(env, '十天后任务', 'next_action',
        scheduled: d10.millisecondsSinceEpoch, sortOrder: 5);
    await pumpPage(tester, env);
    expect(find.byKey(headerKey(d3)), findsOneWidget);
    // 快拖：三天后任务行 → 十天后日期头。
    final gesture = await dragRowTo(tester, '三天后任务', d10);
    await gesture.up();
    await tester.pumpAndSettle();
    // DB：scheduled = 目标日当日 00:00；dueDate 保留（仅安排开始日）；sortOrder 不动（未重排）。
    final aRow = await (env.db.select(env.db.tasks)
          ..where((t) => t.id.equals(a)))
        .getSingle();
    final bRow = await (env.db.select(env.db.tasks)
          ..where((t) => t.id.equals(b)))
        .getSingle();
    expect(aRow.scheduled, DateTime(d10.year, d10.month, d10.day).millisecondsSinceEpoch);
    expect(aRow.dueDate, d10.millisecondsSinceEpoch);
    expect(aRow.sortOrder, 1);
    expect(bRow.sortOrder, 5);
    // 视图：day3 组消失，两任务同落 day10 组。
    expect(find.byKey(headerKey(d3)), findsNothing);
    expect(find.byKey(headerKey(d10)), findsOneWidget);
    expect(find.text('三天后任务'), findsOneWidget);
    expect(find.text('十天后任务'), findsOneWidget);
    await env.db.close();
  });

  testWidgets('不合法目标：拖回当前日期不接受（onWillAccept false，scheduled 不变、无高亮）',
      (tester) async {
    final env = await TestEnv.create();
    final d3 = futureDay(3);
    final d10 = futureDay(10);
    final a = await insertTask(env, '三天后任务', 'next_action',
        scheduled: d3.millisecondsSinceEpoch);
    await insertTask(env, '十天后任务', 'next_action',
        scheduled: d10.millisecondsSinceEpoch);
    await pumpPage(tester, env);
    // 拖三天后任务到自己的日期头（同日期 → 拒绝）。
    final gesture = await dragRowTo(tester, '三天后任务', d3);
    // 悬停无高亮：rejected 不进 candidateData。
    expect(headerBorderColor(tester, d3), Colors.transparent);
    await gesture.up();
    await tester.pumpAndSettle();
    final rows = await env.db.select(env.db.tasks).get();
    final aRow = rows.singleWhere((r) => r.id == a);
    expect(aRow.scheduled, d3.millisecondsSinceEpoch);
    expect(find.byKey(headerKey(d3)), findsOneWidget, reason: '仍在原组');
    expect(find.text('三天后任务'), findsOneWidget);
    await env.db.close();
  });

  testWidgets('悬停日期头高亮：candidateData 非空时描边 primary，释放后落库并复位',
      (tester) async {
    final env = await TestEnv.create();
    final d3 = futureDay(3);
    final d10 = futureDay(10);
    await insertTask(env, '三天后任务', 'next_action',
        scheduled: d3.millisecondsSinceEpoch);
    await insertTask(env, '十天后任务', 'next_action',
        scheduled: d10.millisecondsSinceEpoch);
    await pumpPage(tester, env);
    // 未悬停：透明描边。
    expect(headerBorderColor(tester, d10), Colors.transparent);
    final gesture = await dragRowTo(tester, '三天后任务', d10);
    // 悬停中：描边 = primary（非透明）。
    expect(headerBorderColor(tester, d10), isNot(Colors.transparent));
    await gesture.up();
    await tester.pumpAndSettle();
    // 释放后复位透明；且落库（三天后任务移入 day10 组）。
    expect(headerBorderColor(tester, d10), Colors.transparent);
    final rows = await env.db.select(env.db.tasks).get();
    final aRow = rows.singleWhere((r) => r.title == '三天后任务');
    expect(aRow.scheduled, DateTime(d10.year, d10.month, d10.day).millisecondsSinceEpoch);
    await env.db.close();
  });

  testWidgets('与重排手势分叉：长按拖 = 组内重排（scheduled 不变、不触发拖到日期）',
      (tester) async {
    final env = await TestEnv.create();
    final day = futureDayMs(3);
    final a = await insertTask(env, '任务A', 'next_action', scheduled: day);
    final b = await insertTask(env, '任务B', 'next_action', scheduled: day);
    await pumpPage(tester, env);
    // 长按 A（触屏延迟拖拽 = 重排），不等待即拖是 Draggable 快拖语义——此用例走长按分支。
    final gesture =
        await tester.startGesture(tester.getCenter(find.text('任务A')));
    await tester.pump(kLongPressTimeout + kPressTimeout);
    await gesture.moveBy(const Offset(0, 150));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    // 落库：sortOrder 重排（B 前 A 后）；scheduled 全部不变（拖到日期未触发）。
    final rows = await (env.db.select(env.db.tasks)
          ..where((t) => t.id.isIn([a, b]))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    expect(rows.map((r) => r.id).toList(), [b, a]);
    expect(rows.map((r) => r.scheduled).toList(), [day, day]);
    // 视图顺序即时反映：B 在 A 上。
    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((t) => (t.title as Text).data)
        .toList();
    expect(titles, ['任务B', '任务A']);
    await env.db.close();
  });

  testWidgets('触屏行上纵向快拖 = 拖到日期（显式取舍，滚动让位）：未落日期头则不落库',
      (tester) async {
    final env = await TestEnv.create();
    final day = futureDayMs(3);
    final a = await insertTask(env, '任务A', 'next_action', scheduled: day);
    final b = await insertTask(env, '任务B', 'next_action', scheduled: day);
    await pumpPage(tester, env);
    // 从任务行起手的快速纵向拖动（形似滚动）被 Draggable 判定为拖日期，列表滚动
    // 让位（仅日期头/两侧 padding/滚轮/触屏板承担；取舍见 TaskListView 类注释）。
    // 本用例固定现状：落点不在任何日期头上 → 不落库（scheduled 不变）。
    await tester.drag(find.text('任务A'), const Offset(0, 120));
    await tester.pumpAndSettle();
    final rows = await (env.db.select(env.db.tasks)
          ..where((t) => t.id.isIn([a, b])))
        .get();
    expect(rows.map((r) => r.scheduled).toList(), [day, day]);
    expect(find.text('任务A'), findsOneWidget);
    await env.db.close();
  });
}
