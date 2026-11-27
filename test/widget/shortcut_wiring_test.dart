import 'dart:convert';

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/app/responsive_shell.dart';
import 'package:settle_app/app/window_controller.dart';
import 'package:settle_app/data/providers.dart';
import 'widget_utils.dart';

void main() {
  /// 桌面平台覆盖：widget 测试默认 Android/触屏，快捷键仅桌面启用。
  void useDesktop() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
  }

  /// 发送 Ctrl+Shift+key 完整 down/up 序列（避免硬件键盘状态泄漏）。
  Future<void> sendCtrlShiftKey(
      WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
  }

  testWidgets('rebind collect→X：按 X 打开收集，按 N 无效', (tester) async {
    useDesktop();
    final env = await TestEnv.create();
    await env.prefs.setString(
        'shortcut_bindings', jsonEncode({'collect': {'key': 'KeyX'}}));
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(const ResponsiveShell()));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('collect_dialog_field')), findsOneWidget);
    // 取消收集（CollectDialog 取消按钮无 Key，tap 文本）。
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    // 原绑定 N 已迁移 → 无对话框。
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('collect_dialog_field')), findsNothing);
    await env.db.close();
  });

  testWidgets('Ctrl+Shift+T 切换置顶：fake 记录 + prefs 同步双向', (tester) async {
    useDesktop();
    final env = await TestEnv.create();
    final fake = FakeWindowService();
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(
      const ResponsiveShell(),
      extraOverrides: [windowServiceProvider.overrideWithValue(fake)],
    ));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await sendCtrlShiftKey(tester, LogicalKeyboardKey.keyT);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(ResponsiveShell)));
    expect(container.read(windowControllerProvider).alwaysOnTop, true);
    expect(fake.setAlwaysOnTopCalls, [true]);
    expect(env.prefs.getBool(alwaysOnTopPrefsKey), true);
    // 再按 → 还原。
    await sendCtrlShiftKey(tester, LogicalKeyboardKey.keyT);
    expect(container.read(windowControllerProvider).alwaysOnTop, false);
    expect(fake.setAlwaysOnTopCalls, [true, false]);
    await env.db.close();
  });

  testWidgets('文本输入焦点时 Ctrl+Shift+T 不触发置顶（门控保持）', (tester) async {
    useDesktop();
    final env = await TestEnv.create();
    final fake = FakeWindowService();
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(
      const ResponsiveShell(),
      extraOverrides: [windowServiceProvider.overrideWithValue(fake)],
    ));
    await tester.pump();
    // 切日志页聚焦搜索框（沿用既有用例模式）。
    await tester.tap(find.byKey(const Key('nav_item_8')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('logbook_search')));
    await tester.pump();
    await sendCtrlShiftKey(tester, LogicalKeyboardKey.keyT);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(ResponsiveShell)));
    expect(container.read(windowControllerProvider).alwaysOnTop, false);
    expect(fake.setAlwaysOnTopCalls, isEmpty);
    await env.db.close();
  });
}
