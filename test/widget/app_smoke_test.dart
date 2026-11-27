import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/app/app.dart';

import 'widget_utils.dart';

void main() {
  testWidgets('整应用启动：默认英文，切换中文后导航文案变化（验收①⑧）', (tester) async {
    final env = await TestEnv.create();
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(env));
    await tester.pumpAndSettle();
    expect(find.text('Inbox'), findsWidgets); // 侧边栏 + 页面标题
    // 切到设置页
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('locale_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('中文').last);
    await tester.pumpAndSettle();
    expect(find.text('设置'), findsWidgets); // 语言切换生效
    expect(find.text('收件箱'), findsWidgets);
    await env.db.close();
  });

  testWidgets('外观立即切换、重启后保留，并能恢复跟随系统', (tester) async {
    final env = await TestEnv.create();
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final dispatcher = tester.binding.platformDispatcher;
    dispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(dispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(_app(env));
    await tester.pumpAndSettle();

    Brightness brightness() =>
        Theme.of(tester.element(find.byType(AppBar))).brightness;

    Future<void> openSettings() async {
      await tester.tap(find.byKey(const Key('nav_item_10')));
      await tester.pumpAndSettle();
    }

    Future<void> select(String label) async {
      await tester.tap(find.byKey(const Key('theme_mode_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    await openSettings();
    await select('Dark mode');
    expect(brightness(), Brightness.dark);
    expect(env.prefs.getString('theme_mode'), 'dark');

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_app(env));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);

    dispatcher.platformBrightnessTestValue = Brightness.dark;
    await openSettings();
    await select('Light mode');
    expect(brightness(), Brightness.light);
    final dropdown = find.byKey(const Key('theme_mode_dropdown'));
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byType(DropdownMenuItem<ThemeMode>),
            matching: find.text('Follow system'),
          )
          .hitTestable()
          .last,
    );
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);
    dispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.light);
    await env.db.close();
  });

  testWidgets('窄屏下底部导航五项导航可达（验收①）', (tester) async {
    final env = await TestEnv.create();
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(env));
    await tester.pumpAndSettle();
    // v0.3 起「回顾」不在底部 5 项内，经「更多」抽屉进入
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Empty the inbox, follow up on waiting, advance projects, activate somedays, and check for hard-time conflicts.',
      ),
      findsOneWidget,
    );
    await env.db.close();
  });
}

/// 整应用测试宿主：ProviderScope 注入内存库/mock prefs/Fake 网关 + SettleApp。
Widget _app(TestEnv env) =>
    ProviderScope(overrides: env.overrides, child: const SettleApp());
