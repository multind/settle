// ReminderService + dueReminders 查询测试（v0.3 调度 Task 2）。
// 服务为纯 Dart；轮询用 testWidgets 的 FakeAsync + tester.pump(duration) 驱动
// （仓库惯例：drift import hide isNull/isNotNull；内存库；每测试末尾 close）。
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/app/responsive_shell.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/core/models/task_draft.dart';
import 'package:gtd_app/data/repositories/task_repository.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/task/reminder_service.dart';
import 'package:gtd_app/features/task/task_edit_dialog.dart';
import '../test_utils.dart';
import 'widget_utils.dart';

void main() {
  // 固定基准时刻：repo 与服务共用同一可变时钟，消除真实 now 竞态。
  final t0 = DateTime(2026, 11, 25, 10, 0);

  test('dueReminders 窗口边界：reminderAt == now 命中、== since 不命中、done 排除、asc 排序',
      () async {
    final db = createTestDatabase();
    final repo = TaskRepository(db);
    final a = await repo.create(TaskDraft(
      title: 'a',
      status: TaskStatus.nextAction,
      reminderAt: DateTime.fromMillisecondsSinceEpoch(1000),
    ));
    final b = await repo.create(TaskDraft(
      title: 'b',
      status: TaskStatus.nextAction,
      reminderAt: DateTime.fromMillisecondsSinceEpoch(2000),
    ));
    final done = await repo.create(TaskDraft(
      title: 'done',
      status: TaskStatus.nextAction,
      reminderAt: DateTime.fromMillisecondsSinceEpoch(1500),
    ));
    await repo.complete(done.id);

    // reminderAt == now 命中（since 严格更小）：仅 a 到点（b 未来、done 排除）。
    final hit = await repo.dueReminders(since: 999, now: 1000);
    expect(hit.map((t) => t.id).toList(), [a.id]);

    // reminderAt == since 不命中（严格大于上一轮）。
    expect(await repo.dueReminders(since: 1000, now: 1000), isEmpty);

    // 窗口内按 reminderAt asc，done 排除。
    final ordered = await repo.dueReminders(since: 0, now: 3000);
    expect(ordered.map((t) => t.id).toList(), [a.id, b.id]);

    // 全部未到点（now 早于最早 reminderAt）。
    expect(await repo.dueReminders(since: 0, now: 999), isEmpty);
    await db.close();
  });

  testWidgets('到点触发：reminderAt 在过去窗口内、next_action → emit', (tester) async {
    final db = createTestDatabase();
    var now = t0;
    final repo = TaskRepository(db, now: () => now);
    final task = await repo.create(TaskDraft(
      title: '开会',
      status: TaskStatus.nextAction,
      reminderAt: t0.add(const Duration(seconds: 10)),
    ));
    final service = ReminderService(repo, now: () => now);
    final events = <List<Task>>[];
    // 注意：不 await sub.cancel()——广播流订阅的 cancel Future 在 FakeAsync 区
    // 需要微任务冲刷才会完成，测试体内等待会死锁；service.dispose() 关 controller 即够。
    service.reminders.listen(events.add);
    service.start();
    // 首轮轮询（30s 后，now=t0+30s）：since=0，reminderAt(t0+10s) 在窗口内 → emit。
    now = t0.add(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    expect(events, hasLength(1));
    expect(events.single.map((t) => t.id).toList(), [task.id]);
    service.dispose();
    await db.close();
  });

  testWidgets('同会话不重复：同一任务多轮轮询只 emit 一次', (tester) async {
    final db = createTestDatabase();
    var now = t0;
    final repo = TaskRepository(db, now: () => now);
    final task = await repo.create(TaskDraft(
      title: '不重复',
      status: TaskStatus.nextAction,
      reminderAt: t0.add(const Duration(seconds: 10)),
    ));
    final service = ReminderService(repo, now: () => now);
    final events = <List<Task>>[];
    service.reminders.listen(events.add);
    service.start();
    now = t0.add(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 30)); // 首轮命中
    await tester.pump();
    expect(events, hasLength(1));
    // 第二轮：窗口已越过该 reminderAt，且 notifiedIds 去重 → 不重复 emit。
    now = t0.add(const Duration(seconds: 60));
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    expect(events, hasLength(1));
    expect(events.single.map((t) => t.id).toList(), [task.id]);
    service.dispose();
    await db.close();
  });

  testWidgets('done 任务不触发', (tester) async {
    final db = createTestDatabase();
    var now = t0;
    final repo = TaskRepository(db, now: () => now);
    final task = await repo.create(TaskDraft(
      title: '已完成',
      status: TaskStatus.nextAction,
      reminderAt: t0.add(const Duration(seconds: 10)),
    ));
    await repo.complete(task.id); // → done
    final service = ReminderService(repo, now: () => now);
    final events = <List<Task>>[];
    service.reminders.listen(events.add);
    service.start();
    now = t0.add(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    expect(events, isEmpty);
    service.dispose();
    await db.close();
  });

  testWidgets('reminderAt 在窗口外不触发（future 时间）', (tester) async {
    final db = createTestDatabase();
    var now = t0;
    final repo = TaskRepository(db, now: () => now);
    await repo.create(TaskDraft(
      title: '未来提醒',
      status: TaskStatus.nextAction,
      reminderAt: t0.add(const Duration(hours: 1)),
    ));
    final service = ReminderService(repo, now: () => now);
    final events = <List<Task>>[];
    service.reminders.listen(events.add);
    service.start();
    now = t0.add(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    expect(events, isEmpty);
    service.dispose();
    await db.close();
  });

  testWidgets('shell 挂载：到点逐条弹 Banner，[知道了] 关闭、[打开] 弹编辑对话框',
      (tester) async {
    final env = await TestEnv.create();
    final db = env.db;
    final past = DateTime.now().millisecondsSinceEpoch - 5000;
    // 两条同时到期的任务：首轮命中两条，Banner 逐条排队展示。
    final id1 = await db.into(db.tasks).insert(TasksCompanion.insert(
          title: '到点任务',
          status: TaskStatus.nextAction.storage,
          reminderAt: Value(past),
          createdAt: past,
          updatedAt: past,
        ));
    final id2 = await db.into(db.tasks).insert(TasksCompanion.insert(
          title: '第二个提醒',
          status: TaskStatus.nextAction.storage,
          reminderAt: Value(past),
          createdAt: past,
          updatedAt: past,
        ));
    await tester.binding.setSurfaceSize(const Size(800, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(const ResponsiveShell()));
    await tester.pump();
    // 首轮轮询（30s 后）：service 默认真实时钟，过期提醒命中 → Banner 队列。
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.text('Reminder: 到点任务'), findsOneWidget);
    expect(find.text('Reminder: 第二个提醒'), findsNothing); // 排队中，未入树
    // [知道了]：仅关闭当前 Banner，下一条排队的 Banner 接续展示。
    await tester.tap(find.byKey(Key('reminder_dismiss_$id1')));
    await tester.pumpAndSettle();
    expect(find.text('Reminder: 到点任务'), findsNothing);
    expect(find.text('Reminder: 第二个提醒'), findsOneWidget);
    // [打开]：隐藏当前 Banner 并弹该任务编辑对话框。
    await tester.tap(find.byKey(Key('reminder_open_$id2')));
    await tester.pumpAndSettle();
    expect(find.text('Reminder: 第二个提醒'), findsNothing);
    expect(find.byType(TaskEditDialog), findsOneWidget);
    expect(find.text('Edit task'), findsOneWidget);
    // 关掉对话框，下一轮（60s）同任务已去重 → 不再弹。
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.text('Reminder: 到点任务'), findsNothing);
    expect(find.text('Reminder: 第二个提醒'), findsNothing);
    await env.db.close();
  });
}
