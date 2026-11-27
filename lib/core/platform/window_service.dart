import 'window_service_desktop.dart';
import 'window_service_stub.dart';

/// 窗口能力服务：feature 层只依赖此接口，永不直接接触平台插件。
/// 本轮能力仅置顶（setAlwaysOnTop）；未来托盘/系统通知/全局热键各成
/// service 收进 lib/core/platform/。
abstract class WindowService {
  Future<void> ensureInitialized();
  Future<void> setAlwaysOnTop(bool value);
}

/// 唯一实现选择点：main() 与 provider 共用，避免选择逻辑双份。
/// 桌面 → DesktopWindowService；移动 → NoopWindowService（实现内运行时守卫再兜一层）。
WindowService createWindowService({required bool isDesktop}) =>
    isDesktop ? DesktopWindowService() : NoopWindowService();
