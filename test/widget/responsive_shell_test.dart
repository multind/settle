import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/app/responsive_shell.dart';
import 'package:settle_app/features/someday/someday_page.dart';
import 'package:settle_app/features/today/today_page.dart';
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

  // —— 桌面快捷键（规格 §5）——

  /// 桌面平台覆盖：widget 测试默认 Android/触屏，快捷键仅桌面启用。
  void useDesktop() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
  }

  /// 发送 Ctrl+key 组合（完整 up 序列，避免硬件键盘状态泄漏）。
  Future<void> sendCtrlKey(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(key);
    await tester.sendKeyUpEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
  }

  testWidgets('桌面快捷键：N 打开收集对话框（规格 §5）', (tester) async {
    useDesktop();
    final env = await TestEnv.create();
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(const ResponsiveShell()));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('collect_dialog_field')), findsOneWidget);
    await env.db.close();
  });

  testWidgets('桌面快捷键：启动即用——无任何点击/Tab 直接按 N 打开收集（M-6 修复）',
      (tester) async {
    useDesktop();
    final env = await TestEnv.create();
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(const ResponsiveShell()));
    await tester.pump();
    // 修复前提：启动后 primary focus 落在 shell 内 Focus 锚点（autofocus），
    // 而非 null——否则按键不进入 Shortcuts 子树，快捷键全部失效。
    expect(FocusManager.instance.primaryFocus, isNotNull);
    // 不做任何点击/Tab，直接按 N → 收集对话框弹出。
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('collect_dialog_field')), findsOneWidget);
    await env.db.close();
  });

  testWidgets('桌面快捷键：Ctrl+2 → 今日、Ctrl+5 → 将来也许（侧边栏项序映射，规格 §5）',
      (tester) async {
    useDesktop();
    final env = await TestEnv.create();
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(const ResponsiveShell()));
    await tester.pump();
    // M-6 前提：同 N 用例，先 Tab 建立 shell 内焦点（侧边栏首项）。
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    // Ctrl+2 → 侧边栏第 2 项 = 今日（index 1）。
    await sendCtrlKey(tester, LogicalKeyboardKey.digit2);
    await tester.pumpAndSettle();
    expect(find.byType(TodayPage), findsOneWidget);
    // Ctrl+5 → 侧边栏第 5 项 = 将来也许（index 4）。
    await sendCtrlKey(tester, LogicalKeyboardKey.digit5);
    await tester.pumpAndSettle();
    expect(find.byType(SomedayPage), findsOneWidget);
    await env.db.close();
  });

  testWidgets('移动端（非桌面）：N 不触发收集对话框（快捷键仅桌面启用，M-3）',
      (tester) async {
    // 不调 useDesktop()：widget 测试默认 Android/触屏，shell 不包裹
    // Shortcuts/Actions——若有人误删桌面门控，本用例即红。
    final env = await TestEnv.create();
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(const ResponsiveShell()));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('collect_dialog_field')), findsNothing);
    await env.db.close();
  });

  testWidgets('文本输入焦点时 N 不触发收集对话框（按键进输入框，规格 §5）',
      (tester) async {
    useDesktop();
    final env = await TestEnv.create();
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(const ResponsiveShell()));
    await tester.pump();
    // 切到日志页（常驻搜索输入框）并聚焦输入框。
    await tester.tap(find.byKey(const Key('nav_item_8')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('logbook_search')));
    await tester.pump();
    // 前置断言：primary focus 确实落在 EditableText（TextField 底层）上。
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<EditableText>(),
      isNotNull,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('collect_dialog_field')), findsNothing);
    await env.db.close();
  });
}
