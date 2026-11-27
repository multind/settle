import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:window_manager/window_manager.dart';
import 'window_service.dart';

/// 窗口能力桌面实现：**全仓唯一 import window_manager 的文件**。
/// 内部 `_isSupported` 运行时守卫：非桌面平台（provider 已选 no-op 的兜底
/// 路径）与测试环境（debugDefaultTargetPlatformOverride 非桌面）绝不触
/// 真实插件——避免 MissingPluginException。
class DesktopWindowService implements WindowService {
  static bool get _isSupported =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  Future<void> ensureInitialized() async {
    if (_isSupported) await windowManager.ensureInitialized();
  }

  @override
  Future<void> setAlwaysOnTop(bool value) async {
    if (_isSupported) await windowManager.setAlwaysOnTop(value);
  }
}
