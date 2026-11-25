import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/logbook/logbook_page.dart';
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

  testWidgets('搜索按标题过滤（大小写不敏感，不匹配行消失）', (tester) async {
    final env = await TestEnv.create();
    final ms = DateTime(2026, 11, 25, 10).millisecondsSinceEpoch;
    await insertTask(env, 'Meeting prep', 'done', completedAt: ms);
    await insertTask(env, 'Buy milk', 'done', completedAt: ms);
    await tester.pumpWidget(env.wrap(const LogbookPage()));
    await tester.pump();
    expect(find.text('Meeting prep'), findsOneWidget);
    expect(find.text('Buy milk'), findsOneWidget);
    await tester.enterText(find.byKey(Key('logbook_search')), 'MEET');
    await tester.pump();
    expect(find.text('Meeting prep'), findsOneWidget);
    expect(find.text('Buy milk'), findsNothing);
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
    expect(find.text('No completed tasks yet.'), findsOneWidget);
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
    // 对话框出现：确认前任务仍在。
    expect(find.text('Delete this task?'), findsOneWidget);
    expect(find.text('待删除任务'), findsOneWidget);
    // 点对话框内确认（FilledButton，避免与行内 Delete TextButton 重名冲突）。
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(FilledButton),
    ));
    await tester.pumpAndSettle();
    expect(find.text('待删除任务'), findsNothing);
    expect(find.text('No completed tasks yet.'), findsOneWidget);
    final remaining =
        await (env.db.select(env.db.tasks)..where((t) => t.id.equals(id))).get();
    expect(remaining, isEmpty);
    await env.db.close();
  });

  testWidgets('空态文案', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const LogbookPage()));
    await tester.pump();
    expect(find.text('No completed tasks yet.'), findsOneWidget);
    await env.db.close();
  });
}
