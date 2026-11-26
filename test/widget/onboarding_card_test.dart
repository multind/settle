import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/app/responsive_shell.dart';
import 'package:settle_app/features/guide/gtd_guide_page.dart';
import 'widget_utils.dart';

void main() {
  /// 宽屏整壳：引导卡 in-flow 于内容列顶部（页面 AppBar 之上）。
  Future<void> pumpShellWide(WidgetTester tester, TestEnv env) async {
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(const ResponsiveShell()));
    await tester.pump();
  }

  testWidgets('首启（prefs 空）显示引导卡：标题/铁律/每日动作/CTA', (tester) async {
    final env = await TestEnv.create();
    await pumpShellWide(tester, env);
    expect(find.byKey(const Key('onboarding_card')), findsOneWidget);
    expect(find.text('Welcome to Settle'), findsOneWidget);
    expect(find.text('Capture everything into the inbox'), findsOneWidget);
    expect(find.text('Sunday: 20-minute review'), findsOneWidget);
    expect(find.byKey(const Key('onboarding_open_guide')), findsOneWidget);
    await env.db.close();
  });

  testWidgets('点 × 关闭：卡片消失 + gtd_guide_seen=true，重开壳不再出现', (tester) async {
    final env = await TestEnv.create();
    await pumpShellWide(tester, env);
    await tester.tap(find.byKey(const Key('onboarding_close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('onboarding_card')), findsNothing);
    expect(env.prefs.getBool('gtd_guide_seen'), isTrue);
    // 重新 pump 新壳（同一 prefs 存储）：已看过 → 不再出现。
    await tester.pumpWidget(const SizedBox());
    await pumpShellWide(tester, env);
    expect(find.byKey(const Key('onboarding_card')), findsNothing);
    // 壳替换使旧 InboxPage 的 drift 流退订，drift 以 Timer.run 延迟清理缓存；
    // 无时长的 pump() 不推进假时钟，该 timer 不触发会令 db.close() 在
    // streamQueries.close() 处永久等待（fake async 挂起）。pump(时长) 推进时钟
    // 让 timer 先跑完，再关库。
    await tester.pump(const Duration(seconds: 1));
    await env.db.close();
  });

  testWidgets('预置 gtd_guide_seen=true：首启不出现', (tester) async {
    final env = await TestEnv.create();
    await env.prefs.setBool('gtd_guide_seen', true);
    await pumpShellWide(tester, env);
    expect(find.byKey(const Key('onboarding_card')), findsNothing);
    await env.db.close();
  });

  testWidgets('CTA → 完整指南：卡片消失 + 指南页可见 + flag 置位', (tester) async {
    final env = await TestEnv.create();
    await pumpShellWide(tester, env);
    await tester.tap(find.byKey(const Key('onboarding_open_guide')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('onboarding_card')), findsNothing);
    expect(find.byType(GtdGuidePage), findsOneWidget);
    expect(env.prefs.getBool('gtd_guide_seen'), isTrue);
    await env.db.close();
  });

  testWidgets('卡片 in-flow 不遮挡全局 FAB：今日页卡片与 FAB 同时可见', (tester) async {
    final env = await TestEnv.create();
    await pumpShellWide(tester, env);
    // 切到今日页（今日显示全局收集 FAB）。
    await tester.tap(find.byKey(const Key('nav_item_1')));
    await tester.pumpAndSettle();
    final card = find.byKey(const Key('onboarding_card'));
    final fab = find.byKey(const Key('global_collect_fab'));
    expect(card, findsOneWidget);
    expect(fab, findsOneWidget);
    // 几何验证：卡片底部在 FAB 顶部之上（in-flow 布局不遮挡）。
    expect(tester.getBottomLeft(card).dy < tester.getTopLeft(fab).dy, isTrue);
    await env.db.close();
  });
}
