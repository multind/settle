import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/core/platform/platform_bridge.dart';
import 'package:settle_app/data/providers.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/settings/settings_page.dart';
import 'package:settle_app/features/settings/shortcuts/shortcut_settings_page.dart';
import 'widget_utils.dart';

void main() {
  testWidgets('语言切换写入偏好设置（验收⑦⑧）', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(SettingsPage(onOpenGuide: () {})));
    await tester.tap(find.byKey(const Key('locale_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('中文').last);
    await tester.pumpAndSettle();
    expect(env.prefs.getString('locale'), 'zh');
    await tester.tap(find.byKey(const Key('locale_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    expect(env.prefs.getString('locale'), 'en');
  });

  testWidgets('导出触发 Fake 网关并保存全库 JSON（验收⑦）', (tester) async {
    final env = await TestEnv.create();
    await env.db.into(env.db.inboxItems).insert(InboxItemsCompanion.insert(
      rawText: 'x',
      source: 'text',
      status: 'pending',
      createdAt: 1,
      updatedAt: 1,
    ));
    await tester.pumpWidget(env.wrap(SettingsPage(onOpenGuide: () {})));
    await tester.tap(find.byKey(const Key('export_backup_tile')));
    await tester.pumpAndSettle();
    final map = await env.decodeSavedJson();
    expect(map['app'], 'settle');
    expect(map['inbox_items'], hasLength(1));
  });

  testWidgets('恢复：Fake 返回 JSON 后数据入库（验收⑦）', (tester) async {
    final env = await TestEnv.create();
    env.backup.pickedJson = '{"app":"settle","version":1,"exported_at":1,'
        '"inbox_items":[],"projects":[],'
        '"contexts":[{"id":1,"name":"@电脑","icon":null,"sort":0}],'
        '"tags":[],"tasks":[],"task_tags":[],"reviews":[]}';
    await tester.pumpWidget(env.wrap(SettingsPage(onOpenGuide: () {})));
    await tester.tap(find.byKey(const Key('import_backup_tile')));
    await tester.pumpAndSettle();
    expect(await env.db.select(env.db.contexts).get(), hasLength(1));
  });

  testWidgets('恢复非法备份提示无效且不动数据（§9.1）', (tester) async {
    final env = await TestEnv.create();
    env.backup.pickedJson = '{"app":"x"}';
    await tester.pumpWidget(env.wrap(SettingsPage(onOpenGuide: () {})));
    await tester.tap(find.byKey(const Key('import_backup_tile')));
    await tester.pumpAndSettle();
    expect(find.text('Invalid backup file'), findsOneWidget);
    expect(await env.db.select(env.db.contexts).get(), hasLength(3));
  });

  testWidgets('AI 模型配置为占位入口（M1 范围，规格 §8.1）', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(SettingsPage(onOpenGuide: () {})));
    expect(find.text('AI model config (available in M2)'), findsOneWidget);
  });

  testWidgets('设置页显示 GTD 指南入口（tile）且回调可点', (tester) async {
    var opened = false;
    final env = await TestEnv.create();
    await tester.pumpWidget(
        env.wrap(SettingsPage(onOpenGuide: () => opened = true)));
    expect(find.byKey(const Key('settings_guide_tile')), findsOneWidget);
    expect(find.text('View GTD Guide'), findsOneWidget);
    await tester.tap(find.byKey(const Key('settings_guide_tile')));
    expect(opened, isTrue);
    await env.db.close();
  });

  testWidgets('桌面：置顶开关与快捷键入口两 tile 存在，开关交互落 fake + prefs',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final env = await TestEnv.create();
    final fake = FakeWindowService();
    await tester.pumpWidget(env.wrap(
      SettingsPage(onOpenGuide: () {}),
      extraOverrides: [windowServiceProvider.overrideWithValue(fake)],
    ));
    expect(find.byKey(const Key('settings_always_on_top_tile')), findsOneWidget);
    expect(find.byKey(const Key('settings_shortcuts_tile')), findsOneWidget);
    // 置顶开关：点 → fake 记录 setAlwaysOnTop(true) + prefs；再点 → false。
    await tester.tap(find.byKey(const Key('settings_always_on_top_tile')));
    await tester.pumpAndSettle();
    expect(fake.setAlwaysOnTopCalls, [true]);
    expect(env.prefs.getBool('always_on_top'), true);
    await tester.tap(find.byKey(const Key('settings_always_on_top_tile')));
    await tester.pumpAndSettle();
    expect(fake.setAlwaysOnTopCalls, [true, false]);
    expect(env.prefs.getBool('always_on_top'), false);
    await env.db.close();
  });

  testWidgets('桌面：快捷键入口导航到配置页（AppBar shortcutsTitle）', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(SettingsPage(onOpenGuide: () {})));
    await tester.tap(find.byKey(const Key('settings_shortcuts_tile')));
    await tester.pumpAndSettle();
    expect(find.byType(ShortcutSettingsPage), findsOneWidget);
    expect(find.text('Keyboard Shortcuts'), findsOneWidget);
    await env.db.close();
  });

  testWidgets('移动（bridge override 非桌面）：两 tile 不渲染', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(
      SettingsPage(onOpenGuide: () {}),
      extraOverrides: [
        platformBridgeProvider.overrideWithValue(
            const PlatformBridge(isDesktop: false, isMacOS: false)),
      ],
    ));
    expect(find.byKey(const Key('settings_always_on_top_tile')), findsNothing);
    expect(find.byKey(const Key('settings_shortcuts_tile')), findsNothing);
    await env.db.close();
  });
}
