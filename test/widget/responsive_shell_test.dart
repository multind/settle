import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/app/responsive_shell.dart';
import 'widget_utils.dart';

void main() {
  testWidgets('窄屏（<600）：底部 5 项时间优先（收件箱/今日/即将/随时/更多），无侧边栏', (tester) async {
    final env = await TestEnv.create();
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(const ResponsiveShell()));
    await tester.pump();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byKey(const Key('custom_sidebar')), findsNothing);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    // 时间优先：收件箱/今日/即将/随时/更多
    for (final label in ['Inbox', 'Today', 'Upcoming', 'Anytime', 'More']) {
      expect(find.text(label), findsWidgets);
    }
    await env.db.close();
  });

  testWidgets('宽屏（≥600）：自定义侧边栏 3 组 11 项，无底部导航（规格 §2.2）', (tester) async {
    final env = await TestEnv.create();
    await tester.binding.setSurfaceSize(const Size(800, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(const ResponsiveShell()));
    await tester.pump();
    expect(find.byKey(const Key('custom_sidebar')), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    // 3 组标题（英文 locale）
    expect(find.text('Time'), findsOneWidget);
    expect(find.text('Organize'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    // 11 项（全局索引 0..10）
    for (var i = 0; i <= 10; i++) {
      expect(find.byKey(Key('nav_item_$i')), findsOneWidget);
    }
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

  testWidgets('窄屏「更多」抽屉：6 项，点项目切到项目页（规格 §2.3）', (tester) async {
    final env = await TestEnv.create();
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(const ResponsiveShell()));
    await tester.pump();
    // 打开「更多」抽屉
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    // 抽屉 6 项：项目/情境/等待/日志/回顾/设置（Key 用全局索引）
    for (final i in [5, 6, 7, 8, 9, 10]) {
      expect(find.byKey(Key('nav_more_item_$i')), findsOneWidget);
    }
    // 点「项目」→ 切到项目页并关抽屉
    await tester.tap(find.text('Projects'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nav_more_item_5')), findsNothing);
    expect(find.text('Projects'), findsOneWidget); // 项目页 AppBar 标题
    expect(find.byKey(const Key('new_project_fab')), findsOneWidget);
    // 项目页无全局收集 FAB（显隐集合 {0,5,6,9} 隐藏）
    expect(find.byKey(const Key('global_collect_fab')), findsNothing);
    await env.db.close();
  });
}
