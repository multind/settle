import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'window_service.dart';

/// 平台能力门面：feature/业务代码唯一允许的平台判定入口。
/// 读 defaultTargetPlatform + kIsWeb；经 Riverpod provider 注入，测试可 override。
/// 收敛对象（桌面设置 spec）：responsive_shell `_shortcutsEnabled` 与
/// task_list_view 快捷键门禁的内联判定，全部改经本门面读取。
class PlatformBridge {
  const PlatformBridge({required this.isDesktop, required this.isMacOS});

  /// 桌面（Windows/macOS/Linux，含 Web）：快捷键/置顶等桌面能力门控。
  final bool isDesktop;

  /// macOS：键帽「Ctrl/Cmd 平台自适应」展示判定。
  final bool isMacOS;

  /// 桌面能力门控（快捷键等）：桌面或 Web。语义与旧内联判定逐项等价
  /// （isDesktop 本身已含 kIsWeb），命名聚焦「快捷键/置顶可用」语义。
  bool get supportsKeyboardShortcuts => isDesktop || kIsWeb;

  /// 窗口能力服务：桌面 → DesktopWindowService；移动 → NoopWindowService。
  /// 与 [windowServiceProvider] 共用同一选择工厂，避免选择逻辑双份。
  WindowService get window => createWindowService(isDesktop: isDesktop);

  factory PlatformBridge.detect() {
    final p = defaultTargetPlatform;
    return PlatformBridge(
      isDesktop: kIsWeb ||
          p == TargetPlatform.windows ||
          p == TargetPlatform.macOS ||
          p == TargetPlatform.linux,
      isMacOS: p == TargetPlatform.macOS,
    );
  }
}
