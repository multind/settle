import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/app/responsive_shell.dart';
import 'widget_utils.dart';

void main() {
  testWidgets('窄屏（<600）：底部导航 5 项，无侧边栏（验收①）', (tester) async {
    final env = await TestEnv.create();
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(const ResponsiveShell()));
    await tester.pump();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    await env.db.close();
  });

  testWidgets('宽屏（≥600）：侧边栏 8 项，无底部导航（验收①）', (tester) async {
    final env = await TestEnv.create();
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(const ResponsiveShell()));
    await tester.pump();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    // Flutter 3.50 起 NavigationRailDestination 是数据类而非 Widget，
    // find.byType 无法匹配；改从 NavigationRail.destinations 断言 8 项。
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.destinations, hasLength(8));
    await env.db.close();
  });

  testWidgets('侧边栏切到情境页并展示情境（验收①⑤）', (tester) async {
    final env = await TestEnv.create();
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(const ResponsiveShell()));
    await tester.pump();
    await tester.tap(find.text('Contexts'));
    await tester.pumpAndSettle();
    expect(find.text('@电脑'), findsOneWidget);
    // 按页互斥（spec 2026-11-25）：情境页只显示新建 FAB，不显示全局收集 FAB
    expect(find.byKey(const Key('new_context_fab')), findsOneWidget);
    expect(find.byKey(const Key('global_collect_fab')), findsNothing);
    await env.db.close();
  });

  testWidgets('非收件箱页全局 FAB 一步收集（验收②）', (tester) async {
    final env = await TestEnv.create();
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(const ResponsiveShell()));
    await tester.pump();
    // 先切到非收件箱页（今日），收件箱页本身不显示全局 FAB
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    // 按页互斥（spec 2026-11-25）：今日页无页面级 FAB，仍显示全局收集 FAB
    expect(find.byKey(const Key('global_collect_fab')), findsOneWidget);
    await tester.tap(find.byKey(const Key('global_collect_fab')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('collect_dialog_field')), '给客户回邮件');
    await tester.tap(find.byKey(const Key('collect_dialog_submit')));
    await tester.pumpAndSettle();
    expect(await env.db.select(env.db.inboxItems).get(), hasLength(1));
    await env.db.close();
  });
}
