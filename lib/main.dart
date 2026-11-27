import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settle_app/app/app.dart';
import 'package:settle_app/app/window_controller.dart';
import 'package:settle_app/core/platform/platform_bridge.dart';
import 'package:settle_app/core/platform/window_service.dart';
import 'package:settle_app/data/app_database.dart';
import 'package:settle_app/data/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await openAppDatabase();
  final prefs = await SharedPreferences.getInstance();
  final bridge = PlatformBridge.detect();
  final windowService = createWindowService(isDesktop: bridge.isDesktop);
  await windowService.ensureInitialized(); // 桌面初始化原生窗口插件；移动 no-op
  await restoreAlwaysOnTop(prefs, windowService); // 启动恢复：上次置顶 → 恢复
  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
      windowServiceProvider.overrideWithValue(windowService), // 与 main 构造同一实例
    ],
    child: const SettleApp(),
  ));
}
