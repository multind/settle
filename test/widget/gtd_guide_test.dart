import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/app/responsive_shell.dart';
import 'package:settle_app/app/theme.dart';
import 'package:settle_app/features/guide/gtd_guide_page.dart';
import 'package:settle_app/features/settings/settings_page.dart';
import 'widget_utils.dart';

void main() {
  Future<void> pumpShellWide(WidgetTester tester, TestEnv env,
      {Locale? locale}) async {
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
        env.wrap(const ResponsiveShell(), locale: locale));
    await tester.pump();
    // 首启引导卡（Task 4 起）含铁律/分区标题文案，内容断言前先关闭，避免
    // findsOneWidget 撞车（卡片与指南页文案重复）；Task 3 阶段卡尚不存在，
    // 守卫为空操作——保证本测试文件在 Task 3 与 Task 4 后均稳定。
    if (find.byKey(const Key('onboarding_close')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('onboarding_close')));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('宽屏侧边栏 12 项：nav_item_11 存在，点击直达指南页', (tester) async {
    final env = await TestEnv.create();
    await pumpShellWide(tester, env);
    expect(find.byKey(const Key('nav_item_11')), findsOneWidget);
    expect(find.text('GTD Guide'), findsWidgets); // 侧边栏标签（en）
    await tester.tap(find.byKey(const Key('nav_item_11')));
    await tester.pumpAndSettle();
    expect(find.byType(GtdGuidePage), findsOneWidget);
    await env.db.close();
  });

  testWidgets('窄屏「更多」抽屉 7 项：nav_more_item_11 存在，点击直达指南页',
      (tester) async {
    final env = await TestEnv.create();
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(const ResponsiveShell()));
    await tester.pump();
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nav_more_item_11')), findsOneWidget);
    await tester.tap(find.byKey(const Key('nav_more_item_11')));
    await tester.pumpAndSettle();
    expect(find.byType(GtdGuidePage), findsOneWidget);
    await env.db.close();
  });

  testWidgets('指南页无全局收集 FAB、无页面级 FAB', (tester) async {
    final env = await TestEnv.create();
    await pumpShellWide(tester, env);
    await tester.tap(find.byKey(const Key('nav_item_11')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('global_collect_fab')), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    await env.db.close();
  });

  testWidgets('设置入口：settings_guide_tile 直达指南页且侧边栏选中高亮', (tester) async {
    final env = await TestEnv.create();
    await pumpShellWide(tester, env);
    await tester.tap(find.byKey(const Key('nav_item_10')));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    await tester.tap(find.byKey(const Key('settings_guide_tile')));
    await tester.pumpAndSettle();
    expect(find.byType(GtdGuidePage), findsOneWidget);
    // 选中高亮：nav_item_11 图标色 = AppTokens.light.primary（测试默认浅色主题）。
    final icon = tester.widget<Icon>(find.descendant(
        of: find.byKey(const Key('nav_item_11')),
        matching: find.byType(Icon)));
    expect(icon.color, AppTokens.light.primary);
    await env.db.close();
  });

  testWidgets('指南页四分区内容渲染（en）', (tester) async {
    final env = await TestEnv.create();
    await pumpShellWide(tester, env);
    await tester.tap(find.byKey(const Key('nav_item_11')));
    await tester.pumpAndSettle();
    // 前三分区标题在首屏
    for (final t in ['Three iron rules', 'A daily rhythm', 'How to use each list']) {
      expect(find.text(t), findsOneWidget);
    }
    // 抽样：一条铁律 / 一条规则（标题+正文） / 一条示例
    expect(find.text('Capture everything into the inbox'), findsOneWidget);
    expect(find.text('Collect, don\'t organize'), findsOneWidget);
    expect(
        find.text('Start each item with a verb and state the next action.'),
        findsOneWidget);
    expect(find.text('e.g. "Email the client to confirm the quote"'),
        findsOneWidget);
    // ④ 注意事项在首屏之下，滚动后断言（ListView 惰性构建：以注意事项正文为
    // 滚动目标，确保整张注意事项卡片进入构建范围后再断言标题与正文）。
    await tester.dragUntilVisible(
        find.text('Reminders are in-app only — rely on your own attention for what matters.'),
        find.byKey(const Key('guide_list')), const Offset(0, -300));
    expect(find.text('Notes'), findsOneWidget);
    expect(
        find.text('Reminders are in-app only — rely on your own attention for what matters.'),
        findsOneWidget);
    await env.db.close();
  });

  testWidgets('指南页四分区内容渲染（zh）', (tester) async {
    final env = await TestEnv.create();
    await pumpShellWide(tester, env, locale: const Locale('zh'));
    await tester.tap(find.byKey(const Key('nav_item_11')));
    await tester.pumpAndSettle();
    for (final t in ['三条铁律', '每天固定动作', '各清单使用规则']) {
      expect(find.text(t), findsOneWidget);
    }
    expect(find.text('想到就写进收件箱'), findsOneWidget);
    expect(find.text('只收集，不整理'), findsOneWidget);
    expect(find.text('例：「给客户回邮件，确认报价」'), findsOneWidget);
    await tester.dragUntilVisible(
        find.text('提醒是应用内提示，重要的事请自己留意，别依赖系统级提醒。'),
        find.byKey(const Key('guide_list')), const Offset(0, -300));
    expect(find.text('注意事项'), findsOneWidget);
    expect(find.text('提醒是应用内提示，重要的事请自己留意，别依赖系统级提醒。'),
        findsOneWidget);
    await env.db.close();
  });
}
