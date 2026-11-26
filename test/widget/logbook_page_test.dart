import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/logbook/logbook_page.dart';
import 'widget_utils.dart';

void main() {
  Future<int> insertTask(TestEnv env, String title, String status,
      {int? completedAt}) async {
    return env.db.into(env.db.tasks).insert(TasksCompanion.insert(
      title: title,
      status: status,
      completedAt: Value(completedAt),
      createdAt: 1,
      updatedAt: 1,
    ));
  }

  testWidgets('done 按 completedAt 倒序并显示 yyyy-MM-dd HH:mm 完成时间', (tester) async {
    final env = await TestEnv.create();
    final older = DateTime(2026, 11, 24, 9, 5).millisecondsSinceEpoch;
    final newer = DateTime(2026, 11, 25, 14, 30).millisecondsSinceEpoch;
    await insertTask(env, '旧任务', 'done', completedAt: older);
    await insertTask(env, '新任务', 'done', completedAt: newer);
    await tester.pumpWidget(env.wrap(const LogbookPage()));
    await tester.pump();
    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((t) => (t.title as Text).data)
        .toList();
    expect(titles, ['新任务', '旧任务']);
    expect(find.text('2026-11-25 14:30'), findsOneWidget);
    expect(find.text('2026-11-24 09:05'), findsOneWidget);
    await env.db.close();
  });

  testWidgets('完成时间格式化 1 位月/日补零（yyyy-MM-dd HH:mm）', (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, '单日任务', 'done',
        completedAt: DateTime(2026, 11, 5, 9, 5).millisecondsSinceEpoch);
    await insertTask(env, '单月任务', 'done',
        completedAt: DateTime(2026, 1, 25, 9, 5).millisecondsSinceEpoch);
    await tester.pumpWidget(env.wrap(const LogbookPage()));
    await tester.pump();
    expect(find.text('2026-11-05 09:05'), findsOneWidget);
    expect(find.text('2026-01-25 09:05'), findsOneWidget);
    await env.db.close();
  });

  testWidgets('搜索按标题过滤（大小写不敏感），无匹配显示独立空态', (tester) async {
    final env = await TestEnv.create();
    final ms = DateTime(2026, 11, 25, 10).millisecondsSinceEpoch;
    await insertTask(env, 'Meeting prep', 'done', completedAt: ms);
    await insertTask(env, 'Buy milk', 'done', completedAt: ms);
    await tester.pumpWidget(env.wrap(const LogbookPage()));
    await tester.pump();
    expect(find.text('Meeting prep'), findsOneWidget);
    expect(find.text('Buy milk'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('logbook_search')), 'MEET');
    await tester.pump();
    expect(find.text('Meeting prep'), findsOneWidget);
    expect(find.text('Buy milk'), findsNothing);
    // 无匹配：独立「无匹配任务」文案（区别于归档空态）。
    await tester.enterText(find.byKey(const Key('logbook_search')), 'zzz');
    await tester.pump();
    expect(find.text('Meeting prep'), findsNothing);
    expect(find.text('Buy milk'), findsNothing);
    expect(find.text('No matching tasks.'), findsOneWidget);
    // 清空搜索：全部恢复。
    await tester.enterText(find.byKey(const Key('logbook_search')), '');
    await tester.pump();
    expect(find.text('Meeting prep'), findsOneWidget);
    expect(find.text('Buy milk'), findsOneWidget);
    await env.db.close();
  });

  testWidgets('恢复（reopen）→ next_action、completedAt 清空、行消失', (tester) async {
    final env = await TestEnv.create();
    final id = await insertTask(env, '已完成任务', 'done',
        completedAt: DateTime(2026, 11, 25, 10).millisecondsSinceEpoch);
    await tester.pumpWidget(env.wrap(const LogbookPage()));
    await tester.pump();
    expect(find.text('已完成任务'), findsOneWidget);
    await tester.tap(find.byKey(Key('logbook_reopen_$id')));
    await tester.pumpAndSettle();
    final row =
        await (env.db.select(env.db.tasks)..where((t) => t.id.equals(id))).getSingle();
    expect(row.status, 'next_action');
    expect(row.completedAt, isNull);
    expect(find.text('已完成任务'), findsNothing);
    expect(
        find.text('Completed tasks are kept automatically — count them at your weekly review.'),
        findsOneWidget);
    await env.db.close();
  });

  testWidgets('删除需确认对话框，确认后行消失且硬删除', (tester) async {
    final env = await TestEnv.create();
    final id = await insertTask(env, '待删除任务', 'done',
        completedAt: DateTime(2026, 11, 25, 10).millisecondsSinceEpoch);
    await tester.pumpWidget(env.wrap(const LogbookPage()));
    await tester.pump();
    await tester.tap(find.byKey(Key('logbook_delete_$id')));
    await tester.pumpAndSettle();
    expect(find.text('Delete this task?'), findsOneWidget);
    expect(find.text('待删除任务'), findsOneWidget);
    await tester.tap(find.byKey(const Key('logbook_confirm_delete')));
    await tester.pumpAndSettle();
    expect(find.text('待删除任务'), findsNothing);
    expect(
        find.text('Completed tasks are kept automatically — count them at your weekly review.'),
        findsOneWidget);
    final remaining =
        await (env.db.select(env.db.tasks)..where((t) => t.id.equals(id))).get();
    expect(remaining, isEmpty);
    await env.db.close();
  });

  testWidgets('删除对话框点取消：行仍在、DB 未删', (tester) async {
    final env = await TestEnv.create();
    final id = await insertTask(env, '保留任务', 'done',
        completedAt: DateTime(2026, 11, 25, 10).millisecondsSinceEpoch);
    await tester.pumpWidget(env.wrap(const LogbookPage()));
    await tester.pump();
    await tester.tap(find.byKey(Key('logbook_delete_$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('保留任务'), findsOneWidget);
    final row =
        await (env.db.select(env.db.tasks)..where((t) => t.id.equals(id))).getSingle();
    expect(row.status, 'done');
    await env.db.close();
  });

  testWidgets('窄屏（280dp 逻辑宽）渲染无布局异常', (tester) async {
    tester.view.physicalSize = const Size(280, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await TestEnv.create();
    await insertTask(env, '很长的任务标题用于窄屏渲染验证很长的任务标题用于窄屏渲染验证', 'done',
        completedAt: DateTime(2026, 11, 25, 10).millisecondsSinceEpoch);
    await tester.pumpWidget(env.wrap(const LogbookPage()));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('很长的任务标题用于窄屏渲染验证很长的任务标题用于窄屏渲染验证'), findsOneWidget);
    await env.db.close();
  });

  testWidgets('空态文案', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const LogbookPage()));
    await tester.pump();
    expect(
        find.text('Completed tasks are kept automatically — count them at your weekly review.'),
        findsOneWidget);
    await env.db.close();
  });
}
