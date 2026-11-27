import 'dart:convert';

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/core/shortcuts/shortcut_actions.dart';
import 'package:settle_app/features/settings/shortcuts/shortcut_settings_page.dart';
import 'widget_utils.dart';

void main() {
  void usePlatform(TargetPlatform platform) {
    debugDefaultTargetPlatformOverride = platform;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
  }

  testWidgets('16 行渲染：两组标题 + 全部 shortcut_row_* 存在', (tester) async {
    // ListView 惰性构建：默认 800x600 测试面只 layout 可见 + cache 区子项，
    // 拉高测试面确保两组 16 行全部入树（与接线测试 setSurfaceSize 同款惯例）。
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const ShortcutSettingsPage()));
    await tester.pump();
    expect(find.text('Global'), findsOneWidget);
    expect(find.text('Lists'), findsOneWidget);
    for (final action in shortcutActions) {
      expect(find.byKey(Key('shortcut_row_${action.id}')), findsOneWidget);
    }
    await env.db.close();
  });

  testWidgets('键帽：Windows 下 navInbox 行显 Ctrl+1；macOS 下显 Cmd+1',
      (tester) async {
    usePlatform(TargetPlatform.windows);
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const ShortcutSettingsPage()));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const Key('shortcut_row_navInbox')),
        matching: find.text('Ctrl+1'),
      ),
      findsOneWidget,
    );
    await env.db.close();
  });

  testWidgets('键帽 macOS：navInbox 行显 Cmd+1（平台自适应）', (tester) async {
    usePlatform(TargetPlatform.macOS);
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const ShortcutSettingsPage()));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const Key('shortcut_row_navInbox')),
        matching: find.text('Cmd+1'),
      ),
      findsOneWidget,
    );
    await env.db.close();
  });

  testWidgets('恢复默认：预置自定义 → 确认框 → 键帽回默认', (tester) async {
    final env = await TestEnv.create();
    await env.prefs.setString('shortcut_bindings',
        jsonEncode({'navInbox': {'key': 'KeyA', 'control': true, 'shift': true}}));
    await tester.pumpWidget(env.wrap(const ShortcutSettingsPage()));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const Key('shortcut_row_navInbox')),
        matching: find.text('Ctrl+Shift+A'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('shortcuts_reset')));
    await tester.pumpAndSettle();
    expect(find.text('Reset all shortcuts to their defaults?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('shortcuts_reset_confirm')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('shortcut_row_navInbox')),
        matching: find.text('Ctrl+1'),
      ),
      findsOneWidget,
    );
    expect(env.prefs.getString('shortcut_bindings'), isNull);
    await env.db.close();
  });

  testWidgets('录键后更新：点 collect 行 → 录 Ctrl+X → 键帽变 Ctrl+X',
      (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const ShortcutSettingsPage()));
    await tester.pump();
    await tester.tap(find.byKey(const Key('shortcut_row_collect')));
    await tester.pumpAndSettle();
    // 录 Ctrl+X。
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyX);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyX);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('shortcut_row_collect')),
        matching: find.text('Ctrl+X'),
      ),
      findsOneWidget,
    );
    await env.db.close();
  });
}
