import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/contexts/context_tasks_page.dart';
import 'package:settle_app/features/contexts/contexts_page.dart';
import 'widget_utils.dart';

void main() {
  testWidgets('展示默认情境与新建情境（验收⑤）', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const ContextsPage()));
    await tester.pump(); // 等待 contexts 流首帧数据
    expect(find.text('@电脑'), findsOneWidget);
    await tester.tap(find.byKey(const Key('new_context_fab')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('context_name_field')), '@会议');
    await tester.tap(find.byKey(const Key('context_save')));
    await tester.pumpAndSettle();
    expect(find.text('@会议'), findsOneWidget);
    await env.db.close(); // 关闭 drift 流，避免测试收尾时残留 Timer
  });

  testWidgets('删除情境后关联 Task 的 context_id 置空（验收⑤/§5.2）', (tester) async {
    final env = await TestEnv.create();
    final c = (await env.db.select(env.db.contexts).get()).first; // @电脑
    final taskId = await env.db.into(env.db.tasks).insert(TasksCompanion.insert(
      title: '写方案',
      status: 'next_action',
      contextId: Value(c.id),
      createdAt: 1,
      updatedAt: 1,
    ));
    await tester.pumpWidget(env.wrap(const ContextsPage()));
    await tester.pump(); // 等待 contexts 流首帧数据
    await tester.tap(find.byKey(Key('delete_context_${c.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_delete_context')));
    await tester.pumpAndSettle();
    expect(find.text('@电脑'), findsNothing);
    final row = await (env.db.select(env.db.tasks)..where((t) => t.id.equals(taskId))).getSingle();
    expect(row.contextId, isNull);
    await env.db.close(); // 关闭 drift 流，避免测试收尾时残留 Timer
  });

  testWidgets('点击情境 tile → 打开情境任务页（AppBar @情境名）', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const ContextsPage()));
    await tester.pump(); // 等待 contexts 流首帧数据
    await tester.tap(find.text('@电脑'));
    await tester.pumpAndSettle();
    expect(find.byType(ContextTasksPage), findsOneWidget);
    // AppBar 标题 = 情境名（@ 前缀随输入原样展示）；情境页 tile 已离屏
    // （offstage）不入匹配，find.descendant 限定 AppBar 内唯一命中。
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('@电脑'),
      ),
      findsOneWidget,
    );
    // 种子情境无任务 → 空态文案（contextTasksEmpty）。
    expect(find.text('No tasks in this context'), findsOneWidget);
    await env.db.close();
  });
}
