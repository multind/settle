import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/inbox/inbox_page.dart';
import 'widget_utils.dart';

void main() {
  testWidgets('列表显示原文、来源徽标与状态（验收②）', (tester) async {
    final env = await TestEnv.create();
    await env.db.into(env.db.inboxItems).insert(InboxItemsCompanion.insert(
      rawText: '写周报',
      source: 'text',
      status: 'pending',
      createdAt: 2,
      updatedAt: 2,
    ));
    await env.db.into(env.db.inboxItems).insert(InboxItemsCompanion.insert(
      rawText: '给客户回邮件',
      source: 'text',
      status: 'clarified',
      createdAt: 1,
      updatedAt: 1,
    ));
    await tester.pumpWidget(env.wrap(const InboxPage()));
    await tester.pump();
    expect(find.text('写周报'), findsOneWidget);
    expect(find.text('给客户回邮件'), findsOneWidget);
    expect(find.text('Text'), findsNWidgets(2));
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Clarified'), findsOneWidget);
    await env.db.close();
  });

  testWidgets('删除走二次确认后硬删除（验收②/§5.2）', (tester) async {
    final env = await TestEnv.create();
    final id = await env.db.into(env.db.inboxItems).insert(InboxItemsCompanion.insert(
      rawText: 'x',
      source: 'text',
      status: 'clarified',
      createdAt: 1,
      updatedAt: 1,
    ));
    await tester.pumpWidget(env.wrap(const InboxPage()));
    await tester.pump();
    await tester.tap(find.byKey(Key('delete_inbox_$id')));
    await tester.pumpAndSettle();
    // 先取消
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await env.db.select(env.db.inboxItems).get(), hasLength(1));
    // 再确认删除
    await tester.tap(find.byKey(Key('delete_inbox_$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_delete_inbox')));
    await tester.pumpAndSettle();
    expect(await env.db.select(env.db.inboxItems).get(), isEmpty);
    await env.db.close();
  });

  testWidgets('空收件箱显示空态', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const InboxPage()));
    await tester.pump();
    expect(
        find.text('Start each item with a verb and state the next action.'),
        findsOneWidget);
    await env.db.close();
  });
}
